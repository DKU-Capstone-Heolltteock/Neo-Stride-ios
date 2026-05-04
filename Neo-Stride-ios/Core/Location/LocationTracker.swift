import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationTracker: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var latestLocation: CLLocation?
    @Published private(set) var route: [RunningLocationSample] = []
    @Published private(set) var errorMessage: String?

    private let locationManager: CLLocationManager
    private var onSample: ((RunningLocationSample) -> Void)?

    var canTrackLocation: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    override init() {
        let manager = CLLocationManager()
        self.locationManager = manager
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startTracking(onSample: @escaping (RunningLocationSample) -> Void) {
        self.onSample = onSample
        route.removeAll()
        errorMessage = nil

        if authorizationStatus == .notDetermined {
            requestPermission()
            return
        }

        guard canTrackLocation else {
            errorMessage = "위치 권한을 허용해주세요."
            return
        }

        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        onSample = nil
    }
}

extension LocationTracker: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if authorizationStatus == .denied || authorizationStatus == .restricted {
                errorMessage = "위치 권한을 허용해주세요."
                stopTracking()
            } else if canTrackLocation, onSample != nil {
                locationManager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let sample = RunningLocationSample(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: location.timestamp,
            horizontalAccuracy: location.horizontalAccuracy,
            speed: location.speed
        )

        Task { @MainActor in
            latestLocation = location
            route.append(sample)
            onSample?(sample)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = "위치 정보를 가져오지 못했습니다."
        }
    }
}
