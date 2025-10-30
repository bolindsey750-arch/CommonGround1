import Foundation
import CoreLocation
import MapKit

struct HelpRequest: Identifiable, Hashable {
    let id: UUID
    var title: String        // "Need help moving boxes"
    var details: String      // "I have 4 boxes of books that need to go to my basement."
    var tipAmount: Double?   // optional tip, like 20.0 for $20
    var coordinate: CLLocationCoordinate2D
    var isActive: Bool       // true = still needs help, false = completed/cancelled
    var helperName: String?  // who helped (afterwards)
    var rating: Int?         // stars 1-5 after done
    var isDemo: Bool      // true if this was generated as demo content

    init(
        id: UUID = UUID(),
        title: String,
        details: String,
        tipAmount: Double?,
        coordinate: CLLocationCoordinate2D,
        isActive: Bool,
        helperName: String?,
        rating: Int?,
        isDemo: Bool = false
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.tipAmount = tipAmount
        self.coordinate = coordinate
        self.isActive = isActive
        self.helperName = helperName
        self.rating = rating
        self.isDemo = isDemo
    }

    // MARK: - Manual Equatable / Hashable

    static func == (lhs: HelpRequest, rhs: HelpRequest) -> Bool {
        // Two requests are "the same" if they have the same id.
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        // Only hash stable identity, not mutable fields
        hasher.combine(id)
    }

    // MARK: - Demo content generator

    static func demoRequests(near coord: CLLocationCoordinate2D) -> [HelpRequest] {
        return [
            HelpRequest(
                title: "Carry boxes downstairs",
                details: "Need help carrying 3 old book boxes to basement.",
                tipAmount: 20,
                coordinate: CLLocationCoordinate2D(
                    latitude: coord.latitude + 0.001,
                    longitude: coord.longitude + 0.001
                ),
                isActive: true,
                helperName: nil,
                rating: nil,
                isDemo: true
            ),
            HelpRequest(
                title: "Fix printer / iPad wifi",
                details: "My printer won't connect after I got a new router.",
                tipAmount: nil,
                coordinate: CLLocationCoordinate2D(
                    latitude: coord.latitude - 0.0015,
                    longitude: coord.longitude + 0.0005
                ),
                isActive: true,
                helperName: nil,
                rating: nil,
                isDemo: true
            )
        ]
    }
}
