import MapKit
import SwiftUI

struct RecordRouteMapView: View {
    let traces: [GpsTraceRequest]

    var body: some View {
        Map {
            if traces.count >= 2 {
                MapPolyline(coordinates: traces.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
                    .stroke(NeoStrideColors.accent, lineWidth: 5)
            }
        }
        .mapStyle(.standard(elevation: .flat))
    }
}
