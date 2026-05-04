import SwiftUI

struct RecordsView: View {
    @StateObject private var viewModel: RecordsViewModel
    @State private var navigationPath: [RunningRecord] = []

    init(viewModel: RecordsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                monthHeader

                if viewModel.isLoading && viewModel.records.isEmpty {
                    Spacer()
                    ProgressView("기록을 불러오는 중...")
                        .tint(NeoStrideColors.accent)
                    Spacer()
                } else if viewModel.records.isEmpty {
                    emptyState
                } else {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(NeoStrideColors.warning)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                    }
                    recordsList
                }
            }
            .background(NeoStrideColors.background.ignoresSafeArea())
            .navigationTitle("기록")
            .task { await viewModel.loadMonthlyRecords() }
            .navigationDestination(for: RunningRecord.self) { record in
                RecordDetailView(
                    record: viewModel.recordForDetail(base: record),
                    isLoading: viewModel.isDetailLoading,
                    errorMessage: viewModel.errorMessage
                )
                    .task { await viewModel.loadDetail(for: record) }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                Task { await viewModel.moveMonth(by: -1) }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
            }

            Spacer()

            Text(viewModel.selectedMonth.title)
                .font(.title3.bold())
                .foregroundStyle(NeoStrideColors.primaryText)

            Spacer()

            Button {
                Task { await viewModel.moveMonth(by: 1) }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
            }
        }
        .foregroundStyle(NeoStrideColors.accent)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var recordsList: some View {
        List(viewModel.records) { record in
            Button {
                navigationPath.append(record)
            } label: {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(record.dateText)
                            .font(.caption)
                            .foregroundStyle(NeoStrideColors.secondaryText)
                        Text(record.distanceText)
                            .font(.headline)
                            .foregroundStyle(NeoStrideColors.primaryText)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(record.durationText)
                            .font(.subheadline.bold())
                            .foregroundStyle(NeoStrideColors.primaryText)
                        Text(record.paceText)
                            .font(.caption)
                            .foregroundStyle(NeoStrideColors.secondaryText)
                    }
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(NeoStrideColors.surface)
        }
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.loadMonthlyRecords() }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "figure.run.circle")
                .font(.system(size: 48))
                .foregroundStyle(NeoStrideColors.secondaryText)
            Text("이번 달 러닝 기록이 없습니다.")
                .foregroundStyle(NeoStrideColors.primaryText)
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(NeoStrideColors.warning)
            }
            Spacer()
        }
        .padding(24)
    }
}
