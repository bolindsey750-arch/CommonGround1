import Foundation
import MapKit
import CoreLocation
import Combine

@MainActor
class PlaceSearchManager: ObservableObject {

    @Published var places: [CommunityPlace] = []
    @Published var isSearching: Bool = false

    // You can tweak or expand these terms. We'll query each one.
    private let searchTerms: [(term: String, tags: [String])] = [
        ("youth center", ["Kids", "Teens"]),
        ("community center", ["All Ages"]),
        ("senior center", ["Seniors"]),
        ("public library", ["All Ages", "Teens", "Seniors"]),
        ("recreation center", ["Teens", "All Ages"]),
        ("boys and girls club", ["Kids", "Teens"]),
        ("senior services", ["Seniors"]),
        ("activity center", ["All Ages", "Seniors"])
    ]

    // Call this when we have a user coordinate
    func fetchNearbyPlaces(near coordinate: CLLocationCoordinate2D) {
        // If we’re already loading, don’t spam
        guard isSearching == false else { return }

        isSearching = true
        Task {
            var collected: [CommunityPlace] = []

            // We'll run these searches one by one and gather results
            for (term, tags) in searchTerms {
                let newPlaces = await search(term: term, around: coordinate, defaultTags: tags)
                collected.append(contentsOf: newPlaces)
            }

            // Deduplicate by name + approx coordinate
            let unique = deduplicate(collected)

            // Sort so closest-ish ones tend to float up (simple sort by lat/long distance)
            let sorted = unique.sorted {
                distanceMeters(from: coordinate, to: $0.coordinate) <
                distanceMeters(from: coordinate, to: $1.coordinate)
            }

            self.places = sorted
            self.isSearching = false

            print("🧭 Found \(sorted.count) nearby community spots.")
        }
    }

    // MARK: - Helpers

    private func search(term: String,
                        around coordinate: CLLocationCoordinate2D,
                        defaultTags: [String]) async -> [CommunityPlace] {

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = term
        request.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            let mapped: [CommunityPlace] = response.mapItems.compactMap { item in
                guard let loc = item.placemark.location else { return nil }

                // Name
                let name = item.name ?? "Unknown"

                // Short description / what is it
                // We'll try to build something human-friendly using category + address.
                let category = item.pointOfInterestCategory?.rawValue
                let subtitle = item.placemark.locality ?? item.placemark.title ?? ""
                let descGuess = category ?? subtitle

                // Hours: MapKit doesn’t always give hours; we'll try.
                // item.openingHours is iOS 17+, but it's private-style. We'll fall back to “Hours not available”.
                let hoursText = "Hours not available"

                return CommunityPlace(
                    name: name,
                    description: descGuess,
                    coordinate: loc.coordinate,
                    ageTags: defaultTags,
                    hours: hoursText
                )
            }

            print("🔍 Term '\(term)' -> \(mapped.count) hits")
            return mapped

        } catch {
            print("⚠️ Search for '\(term)' failed: \(error.localizedDescription)")
            return []
        }
    }

    private func deduplicate(_ list: [CommunityPlace]) -> [CommunityPlace] {
        var seen = Set<String>()
        var result: [CommunityPlace] = []

        for place in list {
            // Build a crude key that's "name + rounded coordinate"
            let lat = round(place.coordinate.latitude * 10000) / 10000
            let lon = round(place.coordinate.longitude * 10000) / 10000
            let key = "\(place.name.lowercased())_\(lat)_\(lon)"

            if !seen.contains(key) {
                seen.insert(key)
                result.append(place)
            }
        }
        return result
    }

    private func distanceMeters(from a: CLLocationCoordinate2D,
                                to b: CLLocationCoordinate2D) -> CLLocationDistance {
        let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return locA.distance(from: locB)
    }
}

