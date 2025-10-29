import SwiftUI

struct OnboardingView: View {
    // This is shared with ContentView
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    var body: some View {
        ZStack {
            // subtle gradient background for warmth
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.4),
                    Color.purple.opacity(0.4),
                    Color.black.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Title / pitch
                VStack(spacing: 12) {
                    Text("Find connection near you")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text("This app helps young people and older adults find real community spaces: youth centers, senior centers, libraries, and student tech help hours.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Feature cards / bullets
                VStack(alignment: .leading, spacing: 16) {

                    OnboardingRow(
                        systemIcon: "mappin.and.ellipse",
                        title: "See nearby spaces",
                        detail: "We use your location (only while you're using the app) to show safe places nearby."
                    )

                    OnboardingRow(
                        systemIcon: "person.2.fill",
                        title: "Bridging generations",
                        detail: "Students help seniors with tech. Seniors mentor youth. Everyone belongs."
                    )

                    OnboardingRow(
                        systemIcon: "arrow.triangle.turn.up.right.diamond.fill",
                        title: "Get directions fast",
                        detail: "Tap a pin, read the details, and open it in Maps."
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // Continue button
                Button {
                    // mark onboarding as done
                    hasSeenOnboarding = false
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.blue)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingRow: View {
    let systemIcon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: systemIcon)
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    OnboardingView()
}

