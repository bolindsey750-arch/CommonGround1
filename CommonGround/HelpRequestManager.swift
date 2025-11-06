import Foundation
import CoreLocation
import Combine

final class HelpRequestManager: ObservableObject {
    @Published var requests: [HelpRequest] = []
    
    // ⚙️ Update this line with your ngrok or LAN server URL
    private let baseURL = "https://YOUR-NGROK-URL.ngrok-free.dev"
    
    private let userIdKey = "com.CommonGround.userId"

    // Unique per-user ID (stored persistently)
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
                DispatchQueue.main.async {
                    self.requests = decoded
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
}
