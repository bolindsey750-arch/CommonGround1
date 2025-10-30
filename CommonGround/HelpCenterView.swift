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
    @State private var showingNewRequestSheet = false

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case title
        case details
        case tip
    }

    var body: some View {
        NavigationStack {
            let activeRequests: [HelpRequest] = manager.requests.filter { $0.isActive }
            let finishedRequests: [HelpRequest] = manager.requests.filter { !$0.isActive }

            List {
                Section("Active requests nearby") {
                    ForEach(activeRequests) { req in
                        Button {
                            if !req.isDemo {
                                selectedRequest = req
                            }
                        } label: {
                            HelpRequestRow(req: req)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            trailingActionButton(for: req)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            leadingActionButton(for: req)
                        }
                    }
                }

                Section("Finished / rated") {
                    ForEach(finishedRequests) { req in
                        HelpRequestRow(req: req)
                            .disabled(true)
                            .opacity(0.6)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
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
                    Button("Close") {
                        onClose()
                    }
                }
            }
            .sheet(item: $selectedRequest) { req in
                HelpRequestDetailSheet(
                    request: req,
                    manager: manager,
                    onClose: {
                        selectedRequest = nil
                    }
                )
                .presentationDetents([.fraction(0.4), .large])
            }
            .sheet(isPresented: $showingNewRequestSheet) {
                newRequestSheet
            }
        }
    }

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
                        .background(Color.black.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .focused($focusedField, equals: .details)

                    TextField("Tip (optional $)", text: $newTip)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .tip)
                }
                .padding()
                .safeAreaPadding(.top, 8)
                .foregroundStyle(.primary)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.black.opacity(0.9))
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
        .presentationBackground(Color.black.opacity(0.9))
    }

    @ViewBuilder
    private func trailingActionButton(for req: HelpRequest) -> some View {
        if req.isDemo {
            Button {
                acceptDemo(req)
            } label: {
                Label("Accept", systemImage: "hand.thumbsup.fill")
            }
            .tint(.blue)
        } else {
            Button {
                markDone(req)
            } label: {
                Label("Done", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)
        }
    }

    @ViewBuilder
    private func leadingActionButton(for req: HelpRequest) -> some View {
        if req.isDemo {
            Button {
                declineDemo(req)
            } label: {
                Label("Decline", systemImage: "hand.thumbsdown.fill")
            }
            .tint(.gray)
        } else {
            Button(role: .destructive) {
                cancel(req)
            } label: {
                Label("Cancel", systemImage: "xmark.circle.fill")
            }
        }
    }

    private func acceptDemo(_ req: HelpRequest) {
        if let idx = manager.requests.firstIndex(where: { $0.id == req.id }) {
            manager.requests[idx].isActive = true
        }
    }

    private func markDone(_ req: HelpRequest) {
        if let idx = manager.requests.firstIndex(where: { $0.id == req.id }) {
            manager.requests[idx].isActive = false
        }
    }

    private func cancel(_ req: HelpRequest) {
        if let idx = manager.requests.firstIndex(where: { $0.id == req.id }) {
            manager.requests.remove(at: idx)
        }
    }
    
    private func declineDemo(_ req: HelpRequest) {
        // Remove the demo request from the list when declined
        if let idx = manager.requests.firstIndex(where: { $0.id == req.id }) {
            manager.requests.remove(at: idx)
        }
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
        focusedField = nil
        showingNewRequestSheet = false
    }
}

// Note: This view expects `HelpRequest` to have a `isDemo: Bool` to distinguish demo requests
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

                if req.isActive && req.isDemo {
                    Text("DEMO")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.2))
                        .foregroundStyle(.blue)
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

