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
        // Check cache first
        if let location = currentLocation,
           let lastUpdate = lastLocationUpdate,
           Date().timeIntervalSince(lastUpdate) < cacheExpiry {
            return location
        }

        // Check authorization
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        case .notDetermined:
            requestPermission()
            // Wait a bit for user response
            try? await Task.sleep(for: .milliseconds(500))
            if authorizationStatus != .authorizedWhenInUse && authorizationStatus != .authorizedAlways {
                return nil
            }
        default:
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
        guard let location = locations.first else { return }

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
        print("Location error: \(error)")

        // Resume with nil on error
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }
}
