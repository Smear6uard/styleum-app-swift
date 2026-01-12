import Foundation
import CoreLocation
import MapKit

@Observable
final class LocationService: NSObject {
    static let shared = LocationService()

    private let manager = CLLocationManager()

    // Legacy geocoder for iOS < 26 (deprecated in iOS 26, but kept for backwards compatibility)
    private var _geocoder: Any?
    @available(iOS, deprecated: 26.0)
    private var geocoder: CLGeocoder {
        if _geocoder == nil {
            _geocoder = CLGeocoder()
        }
        return _geocoder as! CLGeocoder
    }

    var currentLocation: CLLocationCoordinate2D?
    var locationName: String = ""
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // Cache
    private var lastLocationUpdate: Date?
    private let cacheExpiry: TimeInterval = 15 * 60 // 15 minutes

    // Continuation with thread-safe access to prevent race conditions
    private let continuationLock = NSLock()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    // Timeout task - stored so it can be cancelled when location arrives
    private var locationTimeoutTask: Task<Void, Never>?

    /// Thread-safe setter for continuation
    private func setContinuation(_ continuation: CheckedContinuation<CLLocationCoordinate2D?, Never>) {
        continuationLock.lock()
        locationContinuation = continuation
        continuationLock.unlock()
    }

    /// Thread-safe resume - atomically clears and resumes to prevent double-resume crashes
    private func resumeContinuationIfNeeded(with result: CLLocationCoordinate2D?) {
        continuationLock.lock()
        let continuation = locationContinuation
        locationContinuation = nil
        continuationLock.unlock()

        continuation?.resume(returning: result)
    }

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
            setContinuation(continuation)
            manager.requestLocation()

            // Timeout after 10 seconds - store task so it can be cancelled
            locationTimeoutTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(10))
                // Check if task was cancelled (location arrived) before timing out
                guard !Task.isCancelled else { return }
                guard let self else { return }
                print("📍 [Location] Timeout after 10s")
                self.resumeContinuationIfNeeded(with: nil)
            }
        }
    }

    // MARK: - Reverse Geocode

    private func reverseGeocode(_ location: CLLocation) async {
        // Use MapKit reverse geocoding for iOS 26+, fall back to CLGeocoder for older versions
        #if compiler(>=6.0)
        if #available(iOS 26.0, *) {
            await reverseGeocodeWithMapKit(location)
        } else {
            await reverseGeocodeWithCLGeocoder(location)
        }
        #else
        await reverseGeocodeWithCLGeocoder(location)
        #endif
    }

    /// Modern reverse geocoding using MapKit (iOS 26+)
    @available(iOS 26.0, *)
    private func reverseGeocodeWithMapKit(_ location: CLLocation) async {
        guard let request = MKReverseGeocodingRequest(location: location) else {
            print("📍 [Location] Failed to create MKReverseGeocodingRequest")
            return
        }
        do {
            let mapItems = try await request.mapItems
            if let mapItem = mapItems.first, let name = mapItem.name {
                await MainActor.run {
                    self.locationName = name
                }
            }
        } catch {
            print("📍 [Location] MapKit reverse geocode failed: \(error)")
        }
    }

    /// Legacy reverse geocoding using CLGeocoder (deprecated in iOS 26)
    @available(iOS, deprecated: 26.0, message: "Use reverseGeocodeWithMapKit instead")
    private func reverseGeocodeWithCLGeocoder(_ location: CLLocation) async {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                await MainActor.run {
                    self.locationName = placemark.locality ?? placemark.administrativeArea ?? ""
                }
            }
        } catch {
            print("📍 [Location] CLGeocoder reverse geocode failed: \(error)")
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

        // Cancel timeout task since we got the location
        locationTimeoutTask?.cancel()
        locationTimeoutTask = nil

        // Resume continuation if waiting (thread-safe)
        resumeContinuationIfNeeded(with: location.coordinate)

        // Reverse geocode in background
        Task {
            await reverseGeocode(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 [Location] Failed with error: \(error.localizedDescription)")

        // Cancel timeout task
        locationTimeoutTask?.cancel()
        locationTimeoutTask = nil

        // Resume with nil on error (thread-safe)
        resumeContinuationIfNeeded(with: nil)
    }
}
