import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus

    override init() {
        self.authorizationStatus = .notDetermined
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone

        // Ask for permission on main thread
        DispatchQueue.main.async {
            print("🔵 Requesting when-in-use authorization…")
            self.manager.requestWhenInUseAuthorization()

            // sync our published status
            self.authorizationStatus = self.manager.authorizationStatus
            self.handleAuthorization()
        }
    }

    // iOS 14+
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("📍 Authorization changed to: \(status.rawValue)")
        authorizationStatus = status
        handleAuthorization()
    }

    // < iOS 14 fallback
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 (legacy) Authorization changed to: \(status.rawValue)")
        authorizationStatus = status
        handleAuthorization()
    }

    private func handleAuthorization() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Authorized, starting location updates…")
            manager.startUpdatingLocation()

        case .denied, .restricted:
            print("❌ Location access denied or restricted.")

        case .notDetermined:
            print("⏳ Waiting for user to grant location access…")

        @unknown default:
            print("🤷 Unknown location authorization state.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        print("📡 Got location update: \(coordinate.latitude), \(coordinate.longitude)")

        DispatchQueue.main.async {
            self.userLocation = coordinate
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("⚠️ Location error: \(error.localizedDescription)")
    }
}
