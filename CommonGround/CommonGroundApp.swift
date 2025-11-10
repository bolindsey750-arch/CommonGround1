import SwiftUI
import FirebaseCore
import FirebaseAuth

// MARK: - Firebase Setup
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // ✅ Configure Firebase before anything else
        FirebaseApp.configure()
        return true
    }
}

// MARK: - App Entry
@main
struct CommonGroundApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @AppStorage("skipOnboarding") private var skipOnboarding: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var hasSeenOnboardingThisLaunch = false
    @State private var isSignedIn = false  // 👈 Start false, initialize later

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if !hasCompletedOnboarding || !hasSeenOnboardingThisLaunch {
                    OnboardingView(hasSeenOnboardingThisLaunch: $hasSeenOnboardingThisLaunch)
                } else if !isSignedIn {
                    SignInView(onLogin: { isSignedIn = true })
                } else {
                    MapScreen() // main app
                }
            }
            .onAppear {
                // 👇 Moved into .onAppear so FirebaseApp.configure runs first
                Auth.auth().addStateDidChangeListener { _, user in
                    isSignedIn = (user != nil)
                }
            }
        }
    }
}
