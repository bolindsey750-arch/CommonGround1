import Foundation
import CoreLocation
import MapKit

struct HelpRequest: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var details: String
    var tipAmount: Double?
    var coordinate: CLLocationCoordinate2D
    var isActive: Bool
    var helperName: String?
    var rating: Int?
    var isDemo: Bool
    var creatorId: String

    enum CodingKeys: String, CodingKey {
        case id, title, details, tipAmount, lat, lng, isActive, helperName, rating, creatorId
    }

    init(
        id: UUID = UUID(),
        title: String,
        details: String,
        tipAmount: Double?,
        coordinate: CLLocationCoordinate2D,
        isActive: Bool,
        helperName: String?,
        rating: Int?,
        creatorId: String,
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
        self.creatorId = creatorId
        self.isDemo = isDemo
    }

    // MARK: - Encode for JSON
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id.uuidString, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(details, forKey: .details)
        try c.encodeIfPresent(tipAmount, forKey: .tipAmount)
        try c.encode(coordinate.latitude, forKey: .lat)
        try c.encode(coordinate.longitude, forKey: .lng)
        try c.encode(isActive, forKey: .isActive)
        try c.encodeIfPresent(helperName, forKey: .helperName)
        try c.encodeIfPresent(rating, forKey: .rating)
        try c.encode(creatorId, forKey: .creatorId)
    }

    // MARK: - Decode from JSON
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let idStr = try c.decode(String.self, forKey: .id)
        id = UUID(uuidString: idStr) ?? UUID()
        title = try c.decode(String.self, forKey: .title)
        details = try c.decode(String.self, forKey: .details)
        tipAmount = try? c.decode(Double.self, forKey: .tipAmount)
        let lat = try c.decode(Double.self, forKey: .lat)
        let lng = try c.decode(Double.self, forKey: .lng)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        isActive = try c.decode(Bool.self, forKey: .isActive)
        helperName = try? c.decode(String.self, forKey: .helperName)
        rating = try? c.decode(Int.self, forKey: .rating)
        creatorId = (try? c.decode(String.self, forKey: .creatorId)) ?? "unknown"
        isDemo = false
    }

    static func == (lhs: HelpRequest, rhs: HelpRequest) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
