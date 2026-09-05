//
//  LLMService.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 05/09/26.
//

import Foundation
import LlamaSwift

enum LLMError: LocalizedError {
    case modelNotFound(String)
    case modelLoadFailed(String)
    case contextInitFailed
    case modelNotLoaded
    case tokenizationFailed
    case decodeFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound(let name):
            return "Model file '\(name)' not found in App Bundle. Please verify Target Membership in Xcode."
        case .modelLoadFailed(let path):
            return "Failed to load GGUF model weights from: \(path)"
        case .contextInitFailed:
            return "Failed to initialize llama context."
        case .modelNotLoaded:
            return "Local AI model is not loaded."
        case .tokenizationFailed:
            return "Failed to tokenize prompt."
        case .decodeFailed:
            return "Failed during llama decode."
        }
    }
}

private actor LLMEngine {
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    
    func loadModel(path: String) throws {
        llama_backend_init()
        
        var modelParams = llama_model_default_params()
        modelParams.n_gpu_layers = 99
        
        guard let loadedModel = llama_model_load_from_file(path, modelParams) else {
            print("[LLMService] Failed to load model from path: \(path)")
            return
        }
        
        var ctxParams = llama_context_default_params()
        ctxParams.n_ctx = 1024
        ctxParams.n_threads = 4
        
        guard let loadedContext = llama_init_from_model(loadedModel, ctxParams) else {
            print("[LLMService] Failed to initialize llama context.")
            
            llama_model_free(loadedModel)
            return
        }
        
        model = loadedModel
        context = loadedContext
    }
    
    func freeResources() {
        if let context = context {
            llama_free(context)
        }
        
        if let model = model {
            llama_model_free(model)
        }
    }
    
    func generate(prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { 
            continuation in
            guard let model = model, let context = context else {
                continuation.finish(throwing: LLMError.modelNotLoaded)
                return
            }
            
            if let memory = llama_get_memory(context) {
                llama_memory_clear(memory, true)
            }
            
            let vocab = llama_model_get_vocab(model)
            
            let utf8 = prompt.utf8
            let maxTokens = Int(utf8.count) + 16
            var tokens = [llama_token](repeating: 0, count: maxTokens)
            let nTokens = llama_tokenize(vocab, prompt, Int32(utf8.count), &tokens, Int32(maxTokens), true, false)
            
            guard nTokens > 0 else {
                continuation.finish(throwing: LLMError.tokenizationFailed)
                return
            }
            
            tokens = Array(tokens.prefix(Int(nTokens)))
            
            var batch = llama_batch_init(Int32(tokens.count), 0, 1)
            for (i, token) in tokens.enumerated() {
                batch.token[i] = token
                batch.pos[i] = Int32(i)
                batch.n_seq_id[i] = 1
                batch.seq_id[i]![0] = 0
                batch.logits[i] = 0
            }
            batch.n_tokens = Int32(tokens.count)
            batch.logits[Int(batch.n_tokens) - 1] = 1
            
            if llama_decode(context, batch) != 0 {
                llama_batch_free(batch)
                continuation.finish(throwing: LLMError.decodeFailed)
                return
            }
            
            let sparams = llama_sampler_chain_default_params()
            let sampler = llama_sampler_chain_init(sparams)
            llama_sampler_chain_add(sampler, llama_sampler_init_temp(0.7))
            llama_sampler_chain_add(sampler, llama_sampler_init_greedy())
            
            var nCur = Int32(batch.n_tokens)
            let nMax: Int32 = 512
            var isLeadingWhitespace = true
            
            while nCur < nMax {
                let newToken = llama_sampler_sample(sampler, context, batch.n_tokens - 1)
                
                if llama_vocab_is_eog(vocab, newToken) {
                    break
                }

                var buf = [CChar](repeating: 0, count: 64)
                let nChars = llama_token_to_piece(vocab, newToken, &buf, Int32(buf.count), 0, false)
                if nChars > 0 {
                    let rawPiece = String(bytes: buf.prefix(Int(nChars)).map { UInt8(bitPattern: $0) }, encoding: .utf8) ?? ""
                    
                    if rawPiece.contains("<|im_end|>") || rawPiece.contains("<|im_start|>") || rawPiece.contains("<|endoftext|>") || rawPiece.contains("<|im_end") || rawPiece.hasPrefix("<|") {
                        let beforeTag = rawPiece.components(separatedBy: "<|").first ?? ""
                        if !beforeTag.isEmpty {
                            continuation.yield(beforeTag)
                        }
                        break
                    }
                    
                    if isLeadingWhitespace {
                        let trimmed = rawPiece.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            isLeadingWhitespace = false
                            continuation.yield(trimmed)
                        }
                    } else if !rawPiece.isEmpty {
                        continuation.yield(rawPiece)
                    }
                }

                llama_batch_free(batch)
                batch = llama_batch_init(1, 0, 1)
                batch.token[0] = newToken
                batch.pos[0] = nCur
                batch.n_seq_id[0] = 1
                batch.seq_id[0]![0] = 0
                batch.logits[0] = 1
                batch.n_tokens = 1
                if llama_decode(context, batch) != 0 { break }

                nCur += 1
            }

            llama_sampler_free(sampler)
            llama_batch_free(batch)
            continuation.finish()
        }
    }
}

@Observable
final class LLMService {
    static let shared = LLMService()
    
    private(set) var isModelLoaded: Bool = false
    private(set) var isGenerating: Bool = false
    
    private let engine = LLMEngine()
    
    init() {
        Task {
            try? await loadModel()
        }
    }
    
    deinit {
        Task { 
            [engine] in
            await engine.freeResources()
        }
    }
    
    func loadModel() async throws {
        if isModelLoaded {
            return
        }
        
        guard let modelPath = Bundle.main.path(forResource: "qwen2.5-0.5b-instruct-q4_k_m", ofType: "gguf") ??
                              Bundle.main.path(forResource: "qwen2.5-0.5b-instruct-q4_k_m", ofType: "gguf", inDirectory: "Resources") ??
                              Bundle.main.url(forResource: "qwen2.5-0.5b-instruct-q4_k_m", withExtension: "gguf")?.path else {
            print("[LLMService] File qwen2.5-0.5b-instruct-q4_k_m.gguf not found in App Bundle.")
            throw LLMError.modelNotFound("qwen2.5-0.5b-instruct-q4_k_m.gguf")
        }
        
        try await engine.loadModel(path: modelPath)
        isModelLoaded = true
        print("[LLMService] Qwen2.5-0.5B on-device successfully loaded into memory!")
    }
    
    func generateStreaming(prompt: String) -> AsyncThrowingStream<String, Error> {
        isGenerating = true
        let stream = AsyncThrowingStream<String, Error> { continuation in
            Task {
                do {
                    try await self.loadModel()
                    
                    let inner = await engine.generate(prompt: prompt)
                    for try await token in inner {
                        continuation.yield(token)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
                isGenerating = false
            }
        }
        return stream
    }
}
