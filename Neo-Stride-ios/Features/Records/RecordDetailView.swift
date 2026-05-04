import SwiftUI

struct RecordDetailView: View {
    let record: RunningRecord
    let isLoading: Bool
    let errorMessage: String?

    init(record: RunningRecord, isLoading: Bool = false, errorMessage: String? = nil) {
        self.record = record
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isLoading {
                    ProgressView("상세 기록을 불러오는 중...")
                        .tint(NeoStrideColors.accent)
                        .frame(maxWidth: .infinity)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(NeoStrideColors.warning)
                }

                RecordRouteMapView(traces: record.route)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text(record.dateText)
                        .font(.headline)
                        .foregroundStyle(NeoStrideColors.secondaryText)
                    Text(record.distanceText)
                        .font(.largeTitle.bold())
                        .foregroundStyle(NeoStrideColors.primaryText)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    detailMetric(title: "시간", value: record.durationText)
                    detailMetric(title: "페이스", value: record.paceText)
                    detailMetric(title: "칼로리", value: record.caloriesText)
                    detailMetric(title: "GPS", value: "\(record.route.count) points")
                }
            }
            .padding(20)
        }
        .background(NeoStrideColors.background.ignoresSafeArea())
        .navigationTitle("기록 상세")
    }

    private func detailMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(NeoStrideColors.secondaryText)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(NeoStrideColors.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(NeoStrideColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
