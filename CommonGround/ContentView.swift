import SwiftUI

struct ContentView: View {
    @Binding var showOnboarding: Bool   // comes from CommonGroundApp

    var body: some View {
        if !showOnboarding {
            OnboardingView(hasSeenOnboardingThisLaunch: $showOnboarding)
        } else {
            MapScreen()
        }
    }
}

#Preview {
    ContentView(showOnboarding: .constant(false))
}
