import SwiftUI

struct HelpRequestDetailSheet: View {
    let request: HelpRequest
    @ObservedObject var manager: HelpRequestManager
    let onClose: () -> Void

    @State private var ratingSelection: Int = 5
    @State private var helperNameInput: String = "Neighbor"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text(request.title)
                .font(.title2).bold()

            Text(request.details)
                .font(.body)

            if let tip = request.tipAmount {
                Text(String(format: "Tip offered: $%.0f", tip))
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }

            if !request.isActive {
                // already completed
                if let helper = request.helperName,
                   let rating = request.rating {
                    Text("Helped by \(helper) — \(rating)★")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Marked complete")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                // Active request controls:
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mark Complete & Rate")
                        .font(.headline)

                    TextField("Helper name", text: $helperNameInput)
                        .textFieldStyle(.roundedBorder)

                    // Star picker 1..5
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= ratingSelection ? "star.fill" : "star")
                                .foregroundStyle(.yellow)
                                .font(.title3)
                                .onTapGesture {
                                    ratingSelection = star
                                }
                        }
                    }

                    // ✅ Mark Done section
                    Button {
                        manager.completeRequest(
                            request,
                            helperName: helperNameInput.isEmpty ? "Neighbor" : helperNameInput,
                            rating: ratingSelection
                        )
                        onClose()
                    } label: {
                        Text("Mark Done")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green)
                            .foregroundStyle(.white)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 12,
                                    style: .continuous
                                )
                            )
                    }

                    // ✅ Cancel section
                    Button(role: .destructive) {
                        manager.cancelRequest(request)
                        onClose()
                    } label: {
                        Text("Cancel Request")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red)
                            .foregroundStyle(.white)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 12,
                                    style: .continuous
                                )
                            )
                    }

                }
            }

            Spacer()

            Button {
                onClose()
            } label: {
                Text("Close")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(24)
    }
}
