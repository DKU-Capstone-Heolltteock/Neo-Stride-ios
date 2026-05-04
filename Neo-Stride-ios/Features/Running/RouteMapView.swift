import MapKit
import SwiftUI

struct RouteMapView: View {
    let samples: [RunningLocationSample]

    var body: some View {
        Map {
            if samples.count >= 2 {
                MapPolyline(coordinates: samples.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
                    .stroke(NeoStrideColors.accent, lineWidth: 5)
            }
        }
        .mapStyle(.standard(elevation: .flat))
    }
}
