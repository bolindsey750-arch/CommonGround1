import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some View {
        if hasSeenOnboarding {
            MapScreen()
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
}
