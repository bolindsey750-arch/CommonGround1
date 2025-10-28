import SwiftUI
import MapKit
import CoreLocation
import Foundation
import Combine

// MARK: - Main Screen

struct MapScreen: View {
    @StateObject private var locationManager = LocationManager()
    @State private var selectedPlace: CommunityPlace? = nil
    @State private var showSheet: Bool = false

    var body: some View {
        ZStack {
            // Instead of `if let`, use presence check and fallback
            Group {
                if locationManager.userLocation == nil {
                    // Still waiting for GPS
                    Color.black.ignoresSafeArea()
                        .overlay(
                            ProgressView("Finding you…")
                                .foregroundStyle(.white)
                        )
                } else {
                    // Safe to force unwrap here because we just checked it's not nil
                    MapReaderView(
                        userCoordinate: locationManager.userLocation!,
                        places: samplePlaces,
                        onSelect: { place in
                            selectedPlace = place
                            showSheet = true
                        }
                    )
                    .ignoresSafeArea()
                }
            }

            BottomGlassPanel()
        }
        .sheet(isPresented: $showSheet) {
            PlaceDetailSheetWrapper(place: selectedPlace)
                .presentationDetents([.fraction(0.35), .large])
        }
        .onReceive(locationManager.$userLocation) { newValue in
            print("User location changed:", String(describing: newValue))
        }
    }
}


// MARK: - Sheet Wrapper (no optional binding in ViewBuilder)

struct PlaceDetailSheetWrapper: View {
    let place: CommunityPlace?

    var body: some View {
        Group {
            if place == nil {
                NoPlaceSelectedView()
            } else {
                // We know it's non-nil in this branch
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


// MARK: - Map View (iOS 17+ Map API)

struct MapReaderView: View {
    let userCoordinate: CLLocationCoordinate2D
    let places: [CommunityPlace]
    let onSelect: (CommunityPlace) -> Void

    @State private var region = MKCoordinateRegion()
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $position) {
            // user's own blue dot
            UserAnnotation()

            // our custom pins
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
            // Initialize camera centered on user's current location
            position = .region(
                MKCoordinateRegion(
                    center: userCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }
        .onMapCameraChange { context in
            // Keep an MKCoordinateRegion approximation in sync
            let center = context.region.center
            let span = context.region.span
            region = MKCoordinateRegion(center: center, span: span)
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
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


// MARK: - Frosted Bottom Panel

struct BottomGlassPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .frame(width: 40, height: 4)
                .opacity(0.4)

            Text("Find a place to connect")
                .font(.title3).bold()

            Text("Tap a pin to see youth centers, senior spaces, tech help hours, and directions.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial) // glass / blur
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
        .shadow(radius: 20)
        .padding()
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}


// MARK: - Detail Sheet Content

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
                Text(place.hours)
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
        let location = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        let dest = MKMapItem(location: location, address: nil)
        dest.name = place.name
        dest.openInMaps()
    }
}

