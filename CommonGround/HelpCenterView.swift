import SwiftUI
import CoreLocation

struct HelpCenterView: View {
    let userLocation: CLLocationCoordinate2D?
    @ObservedObject var manager: HelpRequestManager
    let onClose: () -> Void

    @State private var newTitle: String = ""
    @State private var newDetails: String = ""
    @State private var newTip: String = ""
    @State private var selectedRequest: HelpRequest? = nil
    @State private var showingNewRequestSheet = false

    @FocusState private var focusedField: Field?

    private enum Field: Hashable { case title, details, tip }

    var body: some View {
        NavigationStack {
            let myId = manager.currentUserId
            let myActiveRequests = manager.requests.filter { $0.isActive && $0.creatorId == myId }
            let otherActiveRequests = manager.requests.filter { $0.isActive && $0.creatorId != myId }
            let finishedRequests = manager.requests.filter { !$0.isActive && $0.creatorId == myId }

            List {
                // 🟦 MY ACTIVE REQUESTS
                Section("My Active Requests") {
                    if myActiveRequests.isEmpty {
                        Text("No active requests yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(myActiveRequests) { req in
                            Button { selectedRequest = req } label: {
                                HelpRequestRow(req: req)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                Button {
                                    markDone(req)
                                } label: {
                                    Label("Done", systemImage: "checkmark.circle.fill")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .leading) {
                                Button(role: .destructive) {
                                    cancel(req)
                                } label: {
                                    Label("Cancel", systemImage: "xmark.circle.fill")
                                }
                            }
                        }
                    }
                }

                // 🟨 OTHER USERS' REQUESTS
                Section("Requests from Others") {
                    if otherActiveRequests.isEmpty {
                        Text("No requests from others nearby.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(otherActiveRequests) { req in
                            HelpRequestRow(req: req)
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        acceptRequest(req)
                                    } label: {
                                        Label("Accept", systemImage: "hand.thumbsup.fill")
                                    }
                                    .tint(.blue)
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        declineRequest(req)
                                    } label: {
                                        Label("Decline", systemImage: "hand.thumbsdown.fill")
                                    }
                                    .tint(.gray)
                                }
                        }
                    }
                }

                // ✅ FINISHED REQUESTS
                Section("Finished / Rated") {
                    ForEach(finishedRequests) { req in
                        HelpRequestRow(req: req)
                            .disabled(true)
                            .opacity(0.6)
                    }
                }
            }
            .navigationTitle("Help Center")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingNewRequestSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { onClose() }
                }
            }
            .sheet(isPresented: $showingNewRequestSheet) {
                newRequestSheet
            }
        }
    }

    // MARK: - New Request Sheet
    @ViewBuilder
    private var newRequestSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ask for help")
                        .font(.headline)

                    TextField("What do you need?", text: $newTitle)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .title)

                    Text("More details…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $newDetails)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .focused($focusedField, equals: .details)

                    TextField("Tip (optional $)", text: $newTip)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .tip)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Request")
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") { focusedField = nil }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingNewRequestSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { postNewRequest() }
                        .bold()
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Actions
    private func markDone(_ req: HelpRequest) {
        manager.completeRequest(req, helperName: manager.currentUserId, rating: 5)
    }

    private func cancel(_ req: HelpRequest) {
        manager.deleteRequest(req)
    }

    private func acceptRequest(_ req: HelpRequest) {
        manager.updateRequest(req, fields: [
            "helperName": manager.currentUserId,
            "isActive": true
        ])
    }

    private func declineRequest(_ req: HelpRequest) {
        manager.fetchRequests()
    }

    private func postNewRequest() {
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
        showingNewRequestSheet = false
    }
}

// MARK: - Row View
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
                        .padding(4)
                        .background(.yellow.opacity(0.2))
                        .foregroundStyle(.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Text("DONE")
                        .font(.caption2)
                        .padding(4)
                        .background(.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            Text(req.details)
                .font(.subheadline)
                .foregroundStyle(.secondary)

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
                Text("@\(req.creatorId)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
