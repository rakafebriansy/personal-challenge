import SwiftUI

struct ContentView: View {
    @State private var router = AppRouter.shared
    @State private var permissionManager = PermissionManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("selectedThemeMode") private var themeMode: AppThemeMode = .system

    private var tabSelectionBinding: Binding<AppTab> {
        Binding(
            get: { router.selectedTab },
            set: { newTab in
                if !router.isTabBarDisabled {
                    router.selectedTab = newTab
                }
            }
        )
    }

    var body: some View {
        TabView(selection: tabSelectionBinding) {
            DrawingCanvasScreen()
                .tabItem {
                    Label("Canvas", systemImage: "pencil.and.scribble")
                }
                .accessibilityLabel("Canvas tab")
                .tag(AppTab.canvas)

            if permissionManager.isCameraAuthorized {
                ImageClassificationScreen()
                    .tabItem {
                        Label("Scanner", systemImage: "camera.viewfinder")
                    }
                    .accessibilityLabel("Scanner tab")
                    .tag(AppTab.scanner)
            }
            
            if permissionManager.isMicrophoneAuthorized {
                VoicePronunciationScreen()
                    .tabItem {
                        Label("Voice", systemImage: "mic.fill")
                    }
                    .accessibilityLabel("Voice tab")
                    .tag(AppTab.voice)
            }
            
            ChallengeScreen()
                .tabItem {
                    Label("Challenge", systemImage: "trophy.fill")
                }
                .accessibilityLabel("Challenge tab")
                .tag(AppTab.challenge)
        }
        .overlay(alignment: .bottom) {
            if router.isTabBarDisabled {
                Color.black.opacity(0.001)
                    .frame(maxWidth: .infinity)
                    .frame(height: 84)
                    .contentShape(Rectangle())
                    .onTapGesture { }
                    .ignoresSafeArea(.all, edges: .bottom)
                    .accessibilityHidden(true)
            }
        }
        .preferredColorScheme(themeMode.colorScheme)
        .task {
            await permissionManager.requestAllPermissions()
            validateTabSelection()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                permissionManager.checkPermissions()
                validateTabSelection()
            }
        }
    }
    
    private func validateTabSelection() {
        if router.selectedTab == .scanner && !permissionManager.isCameraAuthorized {
            router.selectedTab = .canvas
        } else if router.selectedTab == .voice && !permissionManager.isMicrophoneAuthorized {
            router.selectedTab = .canvas
        }
    }
}

#Preview("Light Mode") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
