import Foundation
import CoreLocation

struct CommunityPlace: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    let ageTags: [String]
    let hours: String
}

// Temporary hardcoded mock data for judging/demo
let samplePlaces: [CommunityPlace] = [
    CommunityPlace(
        name: "Mineral Point Youth Center",
        description: "After-school hangout, tutoring, games",
        coordinate: CLLocationCoordinate2D(latitude: 42.8600, longitude: -90.1790),
        ageTags: ["Kids", "Teens"],
        hours: "Mon–Fri 3–7 PM"
    ),
    CommunityPlace(
        name: "Senior Community Center",
        description: "Coffee hour, bingo, tech help from students",
        coordinate: CLLocationCoordinate2D(latitude: 42.8608, longitude: -90.1802),
        ageTags: ["Seniors", "All Ages"],
        hours: "Daily 9 AM–2 PM"
    )
]
