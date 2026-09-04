import SwiftUI

struct ContentView: View {
    @State private var router = AppRouter.shared
    
    let hijaiyahList = HijaiyahLetter.allLetters

    var body: some View {
        TabView (selection: $router.selectedTab) {
            ImageClassificationScreen()
                .tabItem {
                    Label("Scanner", systemImage: "camera.viewfinder")
                }
                .tag(AppTab.scanner)
            
            DrawingCanvasScreen()
                .tabItem {
                    Label("Canvas", systemImage: "pencil.and.scribble")
                }
                .tag(AppTab.canvas)
            
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
                Label("Voice", systemImage: "mic.fill")
            }
            .tag(AppTab.voice)
            
            ChallengeScreen()
                .tabItem {
                    Label("Challenge", systemImage: "trophy.fill")
                }
                .tag(AppTab.challenge)
        }
    }
}
