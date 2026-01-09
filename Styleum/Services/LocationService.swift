import Foundation
import CoreLocation

@Observable
final class LocationService: NSObject {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    var currentLocation: CLLocationCoordinate2D?
    var locationName: String = ""
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // Cache
    private var lastLocationUpdate: Date?
    private let cacheExpiry: TimeInterval = 15 * 60 // 15 minutes

    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer // City-level is fine for weather
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Permission

    func requestPermission() {
        guard authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    // MARK: - Get Location

    func getCurrentLocation() async -> CLLocationCoordinate2D? {
        print("📍 [Location] getCurrentLocation() called")

        // Check cache first
        if let location = currentLocation,
           let lastUpdate = lastLocationUpdate,
           Date().timeIntervalSince(lastUpdate) < cacheExpiry {
            print("📍 [Location] Returning cached: \(location.latitude), \(location.longitude)")
            return location
        }

        // Check authorization
        print("📍 [Location] Auth status: \(authorizationStatus.rawValue)")
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 [Location] Authorized, requesting location...")
        case .notDetermined:
            print("📍 [Location] Not determined, requesting permission...")
            requestPermission()
            // Wait a bit for user response
            try? await Task.sleep(for: .milliseconds(500))
            if authorizationStatus != .authorizedWhenInUse && authorizationStatus != .authorizedAlways {
                print("📍 [Location] Permission denied after request")
                return nil
            }
        default:
            print("📍 [Location] Permission denied or restricted")
            return nil
        }

        // Request location
        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()

            // Timeout after 10 seconds
            Task {
                try? await Task.sleep(for: .seconds(10))
                if locationContinuation != nil {
                    print("📍 [Location] Timeout after 10s")
                    locationContinuation?.resume(returning: nil)
                    locationContinuation = nil
                }
            }
        }
    }

    // MARK: - Reverse Geocode

    private func reverseGeocode(_ location: CLLocation) async {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                await MainActor.run {
                    self.locationName = placemark.locality ?? placemark.administrativeArea ?? ""
                }
            }
        } catch {
            print("Reverse geocode failed: \(error)")
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            print("📍 [Location] didUpdateLocations called but no locations")
            return
        }

        print("📍 [Location] Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        currentLocation = location.coordinate
        lastLocationUpdate = Date()

        // Resume continuation if waiting
        locationContinuation?.resume(returning: location.coordinate)
        locationContinuation = nil

        // Reverse geocode in background
        Task {
            await reverseGeocode(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 [Location] Failed with error: \(error.localizedDescription)")

        // Resume with nil on error
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }
}
