import SwiftUI

@main
struct CommonGroundApp: App {
    @AppStorage("skipOnboarding") private var skipOnboarding: Bool = false
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentView(showOnboarding: $showOnboarding)
                .onAppear {
                    // If user chose to skip onboarding, go straight to the main screen
                    showOnboarding = skipOnboarding
                }
        }
    }
}
