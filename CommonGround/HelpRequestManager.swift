import Foundation
import SwiftUI
import Combine
import CoreLocation
import MapKit

/// A simple manager that tracks help requests and notifies SwiftUI when they change.
final class HelpRequestManager: ObservableObject {

    /// The current list of help requests.
    @Published var requests: [HelpRequest]

    // MARK: - Initializer
    init() {
        self.requests = []
    }

    // MARK: - Demo data loader
    func loadInitialDemoRequests(near coord: CLLocationCoordinate2D) {
        if requests.isEmpty {
            requests = HelpRequest.demoRequests(near: coord)
        }
    }

    // MARK: - Post new request
    func postNewRequest(
        title: String,
        details: String,
        tipAmount: Double?,
        at coord: CLLocationCoordinate2D
    ) {
        let newReq = HelpRequest(
            title: title,
            details: details,
            tipAmount: tipAmount,
            coordinate: coord,
            isActive: true,
            helperName: nil,
            rating: nil
        )
        requests.append(newReq)
    }

    // MARK: - Cancel request
    func cancelRequest(_ req: HelpRequest) {
        if let idx = requests.firstIndex(of: req) {
            requests[idx].isActive = false
        }
    }

    // MARK: - Complete & rate request
    func completeRequest(_ req: HelpRequest, helperName: String, rating: Int) {
        if let idx = requests.firstIndex(of: req) {
            requests[idx].isActive = false
            requests[idx].helperName = helperName
            requests[idx].rating = rating
        }
    }
}
