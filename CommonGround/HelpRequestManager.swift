import Foundation
import SwiftUI
import Combine
import CoreLocation
import MapKit

final class HelpRequestManager: ObservableObject {

    // All current requests
    @Published var requests: [HelpRequest] = []
    @Published var isLoading: Bool = false

    // MARK: - Configuration
    private let baseURL = "https://unslanderously-perithecial-mel.ngrok-free.dev"
    private let userIdKey = "com.CommonGround.userId"

    var currentUserId: String {
        if let existing = UserDefaults.standard.string(forKey: userIdKey) {
            return existing
        } else {
            let new = "user_" + UUID().uuidString.prefix(8)
            UserDefaults.standard.set(new, forKey: userIdKey)
            return new
        }
    }

    // MARK: - Load all requests
    func fetchRequests() {
        guard let url = URL(string: "\(baseURL)/requests") else { return }
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async { self.isLoading = false }

            if let error = error {
                print("❌ Fetch error:", error)
                return
            }
            guard let data = data else { return }

            do {
                let decoded = try JSONDecoder().decode([HelpRequest].self, from: data)
                DispatchQueue.main.async {
                    self.requests = decoded
                    print("✅ Loaded \(decoded.count) help requests from server")
                }
            } catch {
                print("❌ Decode error:", error)
                if let s = String(data: data, encoding: .utf8) {
                    print("Server said:", s)
                }
            }
        }.resume()
    }

    // MARK: - Post new request
    func postNewRequest(title: String, details: String, tipAmount: Double?, at coord: CLLocationCoordinate2D) {
        guard let url = URL(string: "\(baseURL)/requests") else { return }

        let body: [String: Any] = [
            "title": title,
            "details": details,
            "tipAmount": tipAmount ?? NSNull(),
            "lat": coord.latitude,
            "lng": coord.longitude,
            "creatorId": currentUserId
        ]

        guard let json = try? JSONSerialization.data(withJSONObject: body) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = json

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Post error:", error)
                return
            }
            guard let data = data else { return }

            do {
                let newReq = try JSONDecoder().decode(HelpRequest.self, from: data)
                DispatchQueue.main.async {
                    self.requests.append(newReq)
                    print("✅ Added new help request:", newReq.title)
                }
            } catch {
                print("❌ Decode error on POST:", error)
                if let s = String(data: data, encoding: .utf8) {
                    print("Server said:", s)
                }
            }
        }.resume()
    }

    // MARK: - Cancel request
    func cancelRequest(_ req: HelpRequest) {
        guard let url = URL(string: "\(baseURL)/requests/\(req.id.uuidString)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ Delete error:", error)
                return
            }
            DispatchQueue.main.async {
                self.requests.removeAll { $0.id == req.id }
                print("🗑️ Deleted help request:", req.title)
            }
        }.resume()
    }

    // MARK: - Mark request done / rate
    func completeRequest(_ req: HelpRequest, helperName: String, rating: Int) {
        guard let url = URL(string: "\(baseURL)/requests/\(req.id.uuidString)") else { return }

        let body: [String: Any] = [
            "isActive": false,
            "helperName": helperName,
            "rating": rating
        ]

        guard let json = try? JSONSerialization.data(withJSONObject: body) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = json

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ Update error:", error)
                return
            }
            DispatchQueue.main.async {
                if let idx = self.requests.firstIndex(of: req) {
                    self.requests[idx].isActive = false
                    self.requests[idx].helperName = helperName
                    self.requests[idx].rating = rating
                    print("✅ Marked request complete:", req.title)
                }
            }
        }.resume()
    }
}
