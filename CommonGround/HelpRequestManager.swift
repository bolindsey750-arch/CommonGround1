import Foundation
import CoreLocation
import Combine

final class HelpRequestManager: ObservableObject {
    @Published var requests: [HelpRequest] = []
    
    // ⚙️ Update this line with your ngrok or LAN server URL
    private let baseURL = "https://unslanderously-perithecial-mel.ngrok-free.dev"
    
    private let userIdKey = "com.CommonGround.userId"
    private let declinedKey = "com.CommonGround.declinedRequests"

    // MARK: - Locally declined requests
    private var declinedIDs: Set<UUID> {
        get {
            let saved = UserDefaults.standard.array(forKey: declinedKey) as? [String] ?? []
            return Set(saved.compactMap { UUID(uuidString: $0) })
        }
        set {
            let arr = newValue.map { $0.uuidString }
            UserDefaults.standard.set(arr, forKey: declinedKey)
        }
    }

    // MARK: - Unique per-user ID
    var currentUserId: String {
        if let existing = UserDefaults.standard.string(forKey: userIdKey) {
            return existing
        } else {
            let newId = "user_" + UUID().uuidString.prefix(6)
            UserDefaults.standard.set(newId, forKey: userIdKey)
            return newId
        }
    }

    // MARK: - Fetch All Requests
    func fetchRequests() {
        guard let url = URL(string: "\(baseURL)/requests") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("❌ Fetch error:", error?.localizedDescription ?? "unknown")
                return
            }
            do {
                let decoded = try JSONDecoder().decode([HelpRequest].self, from: data)
                let declined = self.declinedIDs
                DispatchQueue.main.async {
                    // Filter out declined ones
                    self.requests = decoded.filter { !declined.contains($0.id) }
                }
            } catch {
                print("❌ Decode error:", error)
            }
        }.resume()
    }

    // MARK: - Post New Request
    func postNewRequest(title: String, details: String, tipAmount: Double?, at coord: CLLocationCoordinate2D) {
        guard let url = URL(string: "\(baseURL)/requests") else { return }

        let body: [String: Any] = [
            "title": title,
            "details": details,
            "tipAmount": tipAmount as Any,
            "lat": coord.latitude,
            "lng": coord.longitude,
            "creatorId": currentUserId
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: req) { data, _, error in
            guard let data = data, error == nil else {
                print("❌ Post error:", error?.localizedDescription ?? "unknown")
                return
            }
            do {
                let created = try JSONDecoder().decode(HelpRequest.self, from: data)
                DispatchQueue.main.async {
                    self.requests.append(created)
                }
            } catch {
                print("❌ Post decode error:", error)
            }
        }.resume()
    }

    // MARK: - Update Existing Request
    func updateRequest(_ req: HelpRequest, fields: [String: Any]) {
        guard let url = URL(string: "\(baseURL)/requests/\(req.id)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: fields, options: [])

        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("❌ Update error:", error)
                return
            }
            DispatchQueue.main.async {
                // Simply refetch after update
                self.fetchRequests()
            }
        }.resume()
    }

    // MARK: - Delete Request
    func deleteRequest(_ req: HelpRequest) {
        guard let url = URL(string: "\(baseURL)/requests/\(req.id)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("❌ Delete error:", error)
                return
            }
            DispatchQueue.main.async {
                self.requests.removeAll { $0.id == req.id }
                // Give the server a short moment to process delete
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.fetchRequests()
                }
            }
        }.resume()
    }

    // MARK: - Complete Request (mark done)
    func completeRequest(_ req: HelpRequest, helperName: String, rating: Int) {
        updateRequest(req, fields: [
            "isActive": false,
            "helperName": helperName,
            "rating": rating
        ])
    }

    // MARK: - Decline persistence
    func addDeclined(id: UUID) {
        var declined = declinedIDs
        declined.insert(id)
        declinedIDs = declined
    }

    func removeDeclined(id: UUID) {
        var declined = declinedIDs
        declined.remove(id)
        declinedIDs = declined
    }
}
