import SwiftUI

struct ContentView: View {
    // Daftar huruf untuk dipilih pengguna
    let hijaiyahList: [(letter: String, arabic: String)] = [
        ("alif", "ا"), ("ba", "ب"), ("ta", "ت"), ("tsa", "ث"),
        ("jim", "ج"), ("ha", "ح"), ("kha", "خ"), ("dal", "د"),
        ("dzal", "ذ"), ("ra", "ر"), ("zai", "ز"), ("sin", "س")
        // ... bisa dilengkapi hingga 28 huruf
    ]

    var body: some View {
        TabView {
            ImageClassificationScreen()
                .tabItem {
                    Label("Pemindai", systemImage: "camera.viewfinder")
                }
            
            DrawingCanvasScreen()
                .tabItem {
                    Label("Kanvas", systemImage: "pencil.and.scribble")
                }
            
            // Tab ke-3: Menu Pilih Huruf untuk Latihan Suara
            NavigationStack {
                List(hijaiyahList, id: \.letter) { item in
                    NavigationLink {
                        VoicePronunciationScreen(targetLetter: item.letter, targetArabic: item.arabic)
                    } label: {
                        HStack {
                            Text(item.arabic)
                                .font(.title)
                                .frame(width: 50)
                            Text(item.letter.capitalized)
                                .font(.headline)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("Latihan Suara")
            }
            .tabItem {
                Label("Suara", systemImage: "mic.fill")
            }
        }
    }
}
