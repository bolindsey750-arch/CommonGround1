import SwiftUI
import CoreLocation

struct HelpCenterView: View {
    let userLocation: CLLocationCoordinate2D?
    @ObservedObject var manager: HelpRequestManager
    let onClose: () -> Void

    @State private var newTitle: String = ""
    @State private var newDetails: String = ""
    @State private var newTip: String = ""

    // instead of Bool + optional, we just drive the sheet off this directly
    @State private var selectedRequest: HelpRequest? = nil

    var body: some View {
        NavigationStack {
            List {
                Section("Active requests nearby") {
                    ForEach(manager.requests.filter { $0.isActive }) { req in
                        Button {
                            selectedRequest = req
                        } label: {
                            HelpRequestRow(req: req)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                if let idx = manager.requests.firstIndex(where: { $0.id == req.id }) {
                                    manager.requests[idx].isActive = false
                                }
                            } label: {
                                Label("Done", systemImage: "checkmark.circle.fill")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                if let idx = manager.requests.firstIndex(where: { $0.id == req.id }) {
                                    manager.requests.remove(at: idx)
                                }
                            } label: {
                                Label("Cancel", systemImage: "xmark.circle.fill")
                            }
                        }
                    }
                }

                Section("Finished / rated") {
                    ForEach(manager.requests.filter { !$0.isActive }) { req in
                        HelpRequestRow(req: req)
                            .disabled(true)
                            .opacity(0.6)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ask for help")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    TextField("What do you need?", text: $newTitle)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.black.opacity(0.9), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .foregroundStyle(.primary)

                    TextField("More details…", text: $newDetails, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.black.opacity(0.9), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .foregroundStyle(.primary)

                    TextField("Tip (optional $)", text: $newTip)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.black.opacity(0.9), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .foregroundStyle(.primary)

                    Button {
                        guard let coord = userLocation else { return }
                        let tipVal = Double(newTip)
                        manager.postNewRequest(
                            title: newTitle.isEmpty ? "Help needed" : newTitle,
                            details: newDetails,
                            tipAmount: tipVal,
                            at: coord
                        )
                        newTitle = ""
                        newDetails = ""
                        newTip = ""
                    } label: {
                        Text("Post Request")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color.black)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .navigationTitle("Help Center")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        onClose()
                    }
                }
            }
            // THIS is the important part: sheet(item:)
            .sheet(item: $selectedRequest) { req in
                HelpRequestDetailSheet(
                    request: req,
                    manager: manager,
                    onClose: {
                        // dismiss
                        selectedRequest = nil
                    }
                )
                .presentationDetents([.fraction(0.4), .large])
            }
        }
    }
}

// unchanged row view
struct HelpRequestRow: View {
    let req: HelpRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(req.title)
                    .font(.headline)

                if req.isActive {
                    Text("ACTIVE")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(.yellow.opacity(0.2))
                        .foregroundStyle(.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                } else {
                    Text("DONE")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }

            Text(req.details)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if let tip = req.tipAmount {
                    Text(String(format: "Tip: $%.0f", tip))
                        .font(.footnote)
                        .foregroundStyle(.blue)
                }

                if let rating = req.rating {
                    Text("Rated \(rating)★")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
