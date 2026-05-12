import SwiftUI

struct RunningView: View {
    @StateObject private var locationTracker = LocationTracker()
    @StateObject private var viewModel: RunningViewModel

    init(viewModel: RunningViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                RouteMapView(samples: viewModel.summary.route)
                    .ignoresSafeArea(edges: .top)

                VStack(spacing: 16) {
                    metricsPanel
                    controls
                    watchImportPanel
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(16)
            }
            .background(NeoStrideColors.background.ignoresSafeArea())
            .navigationTitle("러닝")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        locationTracker.requestPermission()
                    } label: {
                        Image(systemName: "location")
                    }
                }
            }
            .onChange(of: viewModel.state) { _, state in
                if state == .running {
                    locationTracker.startTracking { sample in
                        viewModel.add(sample: sample)
                    }
                } else if state == .ready || state == .paused || state == .result {
                    locationTracker.stopTracking()
                }
            }
            .onChange(of: locationTracker.errorMessage) { _, message in
                if let message {
                    viewModel.setError(message)
                }
            }
            .onAppear {
                viewModel.loadPendingWatchSummaries()
            }
        }
    }

    private var metricsPanel: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                metric(title: "거리", value: String(format: "%.2f km", viewModel.summary.distanceKilometers))
                metric(title: "시간", value: formattedDuration(viewModel.summary.durationSeconds))
            }
            HStack(spacing: 12) {
                metric(title: "페이스", value: viewModel.summary.paceMinutesPerKilometer > 0 ? String(format: "%.2f /km", viewModel.summary.paceMinutesPerKilometer) : "--")
                metric(title: "칼로리", value: String(format: "%.0f kcal", viewModel.summary.calories))
            }

            if viewModel.didSaveRecord, let savedRecordId = viewModel.savedRecordId {
                Text("러닝 기록 저장 완료 (#\(savedRecordId))")
                    .font(.footnote)
                    .foregroundStyle(NeoStrideColors.accent)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(NeoStrideColors.warning)
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            switch viewModel.state {
            case .ready:
                Button("러닝 시작") { viewModel.start() }
                    .buttonStyle(.neoStridePrimary)
            case .running:
                HStack(spacing: 12) {
                    Button("일시정지") { viewModel.pause() }
                        .buttonStyle(.borderedProminent)
                    Button("종료") { viewModel.stop() }
                        .buttonStyle(.bordered)
                }
            case .paused:
                HStack(spacing: 12) {
                    Button("다시 시작") { viewModel.resume() }
                        .buttonStyle(.neoStridePrimary)
                    Button("종료") { viewModel.stop() }
                        .buttonStyle(.bordered)
                }
            case .result:
                HStack(spacing: 12) {
                    Button("저장") { Task { await viewModel.save() } }
                        .buttonStyle(.neoStridePrimary)
                    Button("취소") { viewModel.reset() }
                        .buttonStyle(.bordered)
                }
            case .saving:
                ProgressView("저장 중...")
                    .tint(NeoStrideColors.accent)
            }
        }
    }

    @ViewBuilder
    private var watchImportPanel: some View {
        if !viewModel.pendingWatchSummaries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("워치 기록")
                    .font(.headline)
                    .foregroundStyle(NeoStrideColors.primaryText)

                ForEach(viewModel.pendingWatchSummaries.prefix(3)) { summary in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(summary.startedAt, style: .date)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(NeoStrideColors.primaryText)
                                Text("\(String(format: "%.2f km", summary.distanceKilometers)) · \(formattedDuration(summary.durationSeconds)) · \(String(format: "%.2f /km", summary.averagePaceMinutesPerKilometer))")
                                    .font(.caption)
                                    .foregroundStyle(NeoStrideColors.secondaryText)
                            }
                            Spacer()
                            if viewModel.savingWatchSummaryId == summary.id {
                                ProgressView()
                                    .tint(NeoStrideColors.accent)
                            } else {
                                Button("저장") {
                                    Task { await viewModel.saveWatchSummary(summary) }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }

                        HStack(spacing: 12) {
                            Text("심박 \(Int(summary.averageHeartRate.rounded())) bpm")
                            if let cadence = summary.averageCadenceStepsPerMinute {
                                Text("케이던스 \(Int(cadence.rounded())) spm")
                            }
                            Text("GPS \(summary.gpsTraces.count)")
                            Spacer()
                            Button("삭제") {
                                viewModel.discardWatchSummary(id: summary.id)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                        .font(.caption2)
                        .foregroundStyle(NeoStrideColors.secondaryText)
                    }
                    .padding(12)
                    .background(NeoStrideColors.surface.opacity(0.88))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private func metric(title: String, value: String) -> some View {
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
        .background(NeoStrideColors.surface.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
