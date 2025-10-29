import SwiftUI

@main
struct CommonGroundApp: App {
    // This Boolean resets to false each time the app starts
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentView(showOnboarding: $showOnboarding)
                .onAppear {
                    // 👇 When the app launches, force onboarding to show again
                    showOnboarding = false
                }
        }
    }
}
