//
//  HijaiyahLetter.swift
//  hijaiapp
//
//  Created by Raka Febrian Syahputra on 03/09/26.
//

import Foundation
import AppIntents

enum HijaiyahLetter: String, CaseIterable, AppEnum {
    case alif = "alif"
    case ba = "ba"
    case ta = "ta"
    case tsa = "tsa"
    case jim = "jim"
    case ha = "ha"
    case kha = "kha"
    case dal = "dal"
    case dzal = "dzal"
    case ra = "ra"
    case zai = "zai"
    case sin = "sin"
    case syin = "syin"
    case shad = "shad"
    case dhad = "dhad"
    case tha = "tha"
    case zha = "zha"
    case ain = "ain"
    case ghain = "ghain"
    case fa = "fa"
    case qaf = "qaf"
    case kaf = "kaf"
    case lam = "lam"
    case mim = "mim"
    case nun = "nun"
    case haa = "haa"
    case waw = "waw"
    case ya = "ya"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Hijaiyah Letter"
    
    static var allLetters: [(letter: String, arabic: String)] {
        allCases.map {
            ($0.rawValue, $0.arabic)
        }
    }
    
    static var caseDisplayRepresentations: [HijaiyahLetter : DisplayRepresentation] = [
        .alif: DisplayRepresentation(title: "Alif (أ)"),
        .ba: DisplayRepresentation(title: "Ba (ب)"),
        .ta: DisplayRepresentation(title: "Ta (ت)"),
        .tsa: DisplayRepresentation(title: "Tsa (ث)"),
        .jim: DisplayRepresentation(title: "Jim (ج)"),
        .ha: DisplayRepresentation(title: "Ha (ح)"),
        .kha: DisplayRepresentation(title: "Kha (خ)"),
        .dal: DisplayRepresentation(title: "Dal (د)"),
        .dzal: DisplayRepresentation(title: "Dzal (ذ)"),
        .ra: DisplayRepresentation(title: "Ra (ر)"),
        .zai: DisplayRepresentation(title: "Zai (ز)"),
        .sin: DisplayRepresentation(title: "Sin (س)"),
        .syin: DisplayRepresentation(title: "Syin (ش)"),
        .shad: DisplayRepresentation(title: "Shad (ص)"),
        .dhad: DisplayRepresentation(title: "Dhad (ض)"),
        .tha: DisplayRepresentation(title: "Tha (ط)"),
        .zha: DisplayRepresentation(title: "Zha (ظ)"),
        .ain: DisplayRepresentation(title: "Ain (ع)"),
        .ghain: DisplayRepresentation(title: "Ghain (غ)"),
        .fa: DisplayRepresentation(title: "Fa (ف)"),
        .qaf: DisplayRepresentation(title: "Qaf (ق)"),
        .kaf: DisplayRepresentation(title: "Kaf (ك)"),
        .lam: DisplayRepresentation(title: "Lam (ل)"),
        .mim: DisplayRepresentation(title: "Mim (م)"),
        .nun: DisplayRepresentation(title: "Nun (ن)"),
        .haa: DisplayRepresentation(title: "Haa (هـ)"),
        .waw: DisplayRepresentation(title: "Waw (و)"),
        .ya: DisplayRepresentation(title: "Ya (ي)")
    ]
    
    var arabic: String {
        switch self {
        case .alif: return "ا"
        case .ba: return "ب"
        case .ta: return "ت"
        case .tsa: return "ث"
        case .jim: return "ج"
        case .ha: return "ح"
        case .kha: return "خ"
        case .dal: return "د"
        case .dzal: return "ذ"
        case .ra: return "ر"
        case .zai: return "ز"
        case .sin: return "س"
        case .syin: return "ش"
        case .shad: return "ص"
        case .dhad: return "ض"
        case .tha: return "ط"
        case .zha: return "ظ"
        case .ain: return "ع"
        case .ghain: return "غ"
        case .fa: return "ف"
        case .qaf: return "ق"
        case .kaf: return "ك"
        case .lam: return "ل"
        case .mim: return "م"
        case .nun: return "ن"
        case .haa: return "هـ"
        case .waw: return "و"
        case .ya: return "ي"
        }
    }
    
    var displayName: String {
        "\(rawValue.capitalized) (\(arabic))"
    }
    
    static func from(audioLabel: String) -> HijaiyahLetter? {
        let clean = audioLabel.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if let direct = HijaiyahLetter(rawValue: clean) {
            return direct
        }
        
        let components = clean.components(separatedBy: "_")
        if components.count >= 2, let number = Int(components[0]) {
            let index = number - 1
            let namePart = components.dropFirst().joined(separator: "_")
            if let fromName = matchByName(namePart) {
                return fromName
            }
            if index >= 0 && index < allCases.count {
                return allCases[index]
            }
        }
        
        return matchByName(clean)
    }
    
    private static func matchByName(_ name: String) -> HijaiyahLetter? {
        let n = name.replacingOccurrences(of: "^[0-9]+", with: "", options: .regularExpression)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "_- "))
        
        switch n {
        case "alif", "a": return .alif
        case "ba": return .ba
        case "ta": return .ta
        case "tsa", "sa": return .tsa
        case "jim", "ja": return .jim
        case "ha": return .ha
        case "kha", "kho": return .kha
        case "dal", "da": return .dal
        case "dzal", "dza": return .dzal
        case "ra", "ro": return .ra
        case "zai", "zay", "za": return .zai
        case "sin": return .sin
        case "syin", "shin", "sya": return .syin
        case "shad", "sho", "sad": return .shad
        case "dhad", "dho", "dad": return .dhad
        case "tha", "tho": return .tha
        case "zha", "zho", "zhaa": return .zha
        case "ain", "aa", "ayn": return .ain
        case "ghain", "ghoin", "gha": return .ghain
        case "fa": return .fa
        case "qaf", "qof", "qa": return .qaf
        case "kaf", "ka": return .kaf
        case "lam", "la": return .lam
        case "mim", "ma": return .mim
        case "nun", "na": return .nun
        case "haa", "ha2": return .haa
        case "waw", "wa": return .waw
        case "ya": return .ya
        default: return HijaiyahLetter(rawValue: n)
        }
    }
}
