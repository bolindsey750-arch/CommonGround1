import SwiftUI
import MapKit
import CoreLocation
import Foundation
import Combine

// MARK: - Main Screen

struct MapScreen: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchManager = PlaceSearchManager()

    @State private var selectedPlace: CommunityPlace? = nil
    @State private var showSheet: Bool = false

    // track if we've already centered camera once
    @State private var didSetInitialCamera = false

    // track if we've already triggered a search so we don't spam repeat lookups
    @State private var didSearchForPlaces = false

    var body: some View {
        ZStack {
            mainContent

            BottomGlassPanel(
                selectedPlace: selectedPlace,
                isExpanded: showSheet
            )
        }
        .sheet(isPresented: $showSheet, onDismiss: {
            // when the detail sheet is closed, clear selection so the bar goes
            // back to "Find a place to connect"
            selectedPlace = nil
        }) {
            PlaceDetailSheetWrapper(place: selectedPlace)
                .presentationDetents([.fraction(0.35), .large])
        }
        .onReceive(locationManager.$authorizationStatus) { status in
            print("👀 MapScreen sees auth status:", status.rawValue)
        }
        .onReceive(locationManager.$userLocation) { coord in
            print("👀 MapScreen sees userLocation:", String(describing: coord))
        }
        .onReceive(searchManager.$places) { newPlaces in
            print("📍 MapScreen got \(newPlaces.count) places from searchManager")
        }
    }

    // MARK: - Main map / state logic
    @ViewBuilder
    private var mainContent: some View {
        switch locationManager.authorizationStatus {

        case .notDetermined:
            LoadingStateView(message: "Requesting location access…")

        case .denied, .restricted:
            LocationDeniedView()

        case .authorizedAlways, .authorizedWhenInUse:
            if let userCoord = locationManager.userLocation {

                ZStack {
                    MapReaderView(
                        userCoordinate: userCoord,
                        places: searchManager.places,
                        onSelect: { place in
                            selectedPlace = place
                            showSheet = true
                        },
                        didSetInitialCamera: $didSetInitialCamera
                    )
                    .ignoresSafeArea()

                    if searchManager.isSearching {
                        VStack(spacing: 8) {
                            ProgressView()
                            Text("Looking for nearby community spots…")
                                .font(.footnote)
                                .foregroundStyle(.white)
                        }
                        .padding(12)
                        .background(.black.opacity(0.6))
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                        )
                        .padding(.bottom, 120)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
                // trigger the place search when map content FIRST appears
                .onAppear {
                    if !didSearchForPlaces {
                        didSearchForPlaces = true
                        print("🛰 Fetching nearby places once at userCoord \(userCoord.latitude), \(userCoord.longitude)")
                        searchManager.fetchNearbyPlaces(near: userCoord)
                    }
                }

            } else {
                LoadingStateView(message: "Finding you…")
            }

        @unknown default:
            LoadingStateView(message: "Loading…")
        }
    }
}


// MARK: - State Views

struct LoadingStateView: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .tint(.white)
                Text(message)
                    .foregroundStyle(.white)
                    .font(.callout)
            }
        }
    }
}

struct LocationDeniedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)

            Text("Location is Off")
                .font(.headline)

            Text("We use your location to show nearby community spots. You can turn it on in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}


// MARK: - Map View (iOS 17+ Map API)

struct MapReaderView: View {
    let userCoordinate: CLLocationCoordinate2D
    let places: [CommunityPlace]
    let onSelect: (CommunityPlace) -> Void

    @Binding var didSetInitialCamera: Bool

    @State private var region = MKCoordinateRegion()
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        ZStack {
            Map(position: $position) {
                // User's location blue dot
                UserAnnotation()

                // Pins for each returned place
                ForEach(places) { place in
                    Annotation(place.name,
                               coordinate: place.coordinate,
                               anchor: .bottom) {

                        Button {
                            onSelect(place)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.red, .white)

                                Text(shortName(place.name))
                                    .font(.caption2)
                                    .padding(4)
                                    .background(.ultraThinMaterial)
                                    .clipShape(
                                        RoundedRectangle(
                                            cornerRadius: 6,
                                            style: .continuous
                                        )
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .onAppear {
                if !didSetInitialCamera {
                    print("🗺 Setting initial camera around user at \(userCoordinate.latitude), \(userCoordinate.longitude)")
                    position = .region(
                        MKCoordinateRegion(
                            center: userCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                    didSetInitialCamera = true
                }
            }
            .onMapCameraChange { context in
                let center = context.region.center
                let span = context.region.span
                region = MKCoordinateRegion(center: center, span: span)
            }

            // CUSTOM FLOATING CONTROLS OVERLAY
            VStack {
                HStack {
                    Spacer()

                    VStack(spacing: 12) {
                        // recenter button
                        Button {
                            // animate camera back to user
                            withAnimation(.easeInOut(duration: 0.25)) {
                                position = .region(
                                    MKCoordinateRegion(
                                        center: userCoordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    )
                                )
                            }
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(
                                                    Color.white.opacity(0.4),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                        }
                        .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 8)

                        // compass from MapKit, but styled-floating
                        MapCompass()
                            .mapControlVisibility(.visible) // make sure compass is active
                    }
                    // tweak these paddings to move the stack where you want
                    .padding(.top, 60)      // <- lower this number to push it DOWN
                    .padding(.trailing, 16) // <- space from right edge
                }

                Spacer()
            }
            .allowsHitTesting(true)
        }
    }

    private func shortName(_ full: String) -> String {
        if full.count > 18 {
            let idx = full.index(full.startIndex, offsetBy: 18)
            return String(full[..<idx]) + "…"
        } else {
            return full
        }
    }
}


// MARK: - Bottom overlay panel (liquid glass style with fixed rounded corners)

struct BottomGlassPanel: View {
    let selectedPlace: CommunityPlace?
    let isExpanded: Bool

    private let cornerRadius: CGFloat = 28

    var body: some View {
        // Content inside the bubble
        let content = VStack(alignment: .leading, spacing: 10) {
            // If the sheet is up AND we have a selected place, show that place.
            // Otherwise, show the generic helper text.
            if isExpanded, let place = selectedPlace {
                Text(place.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(place.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

            } else {
                Text("Find a place to connect")
                    .font(.title3).bold()

                Text("Tap a pin to see youth spaces, senior centers, libraries, and tech help opportunities.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)

        content
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // frosted base
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // pearly highlight layer
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.45),
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.screen)
                        .opacity(0.6)

                    // subtle border / rim light
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .opacity(0.8)
                }
            )
            // hard clip to the same radius so we don't get that weird square edge
            .clipShape(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            // lift off the map
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 16)
            .padding(.horizontal)
            .padding(.bottom, 16)
            .frame(maxHeight: .infinity, alignment: .bottom)
            // tiny "alive" scale bump when expanded
            .scaleEffect(isExpanded ? 1.02 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
    }
}


// MARK: - Sheet Wrapper + Sheet

struct PlaceDetailSheetWrapper: View {
    let place: CommunityPlace?

    var body: some View {
        Group {
            if place == nil {
                NoPlaceSelectedView()
            } else {
                PlaceDetailSheet(place: place!)
            }
        }
    }
}

struct NoPlaceSelectedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("No place selected")
                .font(.headline)
            Text("Tap a pin on the map to see details.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct PlaceDetailSheet: View {
    let place: CommunityPlace

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text(place.name)
                .font(.title2).bold()

            Text(place.description)
                .font(.body)

            HStack {
                Image(systemName: "clock")
                Text(place.hours.isEmpty ? "Hours not available" : place.hours)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack {
                ForEach(place.ageTags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }

            Button {
                openInMaps()
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    Text("Get Directions")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                )
            }

            Spacer()
        }
        .padding(24)
    }

    private func openInMaps() {
        let placemark = MKPlacemark(
            coordinate: place.coordinate,
            addressDictionary: nil
        )
        let item = MKMapItem(placemark: placemark)
        item.name = place.name
        item.openInMaps()
    }
}
