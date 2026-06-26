import SwiftUI
import FirebaseCore

@main
struct BinWise_CindiApp: App {

    @StateObject private var historyStore  = HistoryStore()
    @StateObject private var quizStore     = QuizStore()
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var authVM        = AuthViewModel()

    /// True after the minimum splash duration has elapsed.
    @State private var splashDone = false

    init() {
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           !path.isEmpty {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .environmentObject(historyStore)
                .environmentObject(quizStore)
                .environmentObject(settingsStore)
                .environmentObject(authVM)
                .environment(\.appLanguage, settingsStore.language)
                .onAppear {
                    StaticDataService.seedIfNeeded(historyStore: historyStore, quizStore: quizStore)
                }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        // Show the animated splash until BOTH the 1.5 s minimum AND Firebase auth check are done.
        if !splashDone || authVM.isCheckingAuth {
            SplashView()
                .task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    withAnimation(.easeInOut(duration: 0.35)) {
                        splashDone = true
                    }
                }
        } else if !settingsStore.hasSeenOnboarding {
            OnboardingView()
        } else if authVM.sessionConfirmed {
            MainTabView()
        } else {
            // Always land here after onboarding — even if Firebase already restored a
            // session from disk — so Sign In/Sign Up (or "Continue as…") is visibly
            // exercised every app launch instead of silently skipping to MainTabView.
            AuthView()
        }
    }
}
