import Foundation
import CoreLocation
import MapKit

struct CommunityPlace: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    let ageTags: [String]
    let hours: String

    // MARK: - Manual Hashable / Equatable
    static func == (lhs: CommunityPlace, rhs: CommunityPlace) -> Bool {
        lhs.name == rhs.name &&
        abs(lhs.coordinate.latitude - rhs.coordinate.latitude) < 0.0001 &&
        abs(lhs.coordinate.longitude - rhs.coordinate.longitude) < 0.0001
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name.lowercased())
        hasher.combine(round(coordinate.latitude * 10000))
        hasher.combine(round(coordinate.longitude * 10000))
    }
}
