import SwiftUI

struct GoalSettingView: View {
    @ObservedObject var viewModel: CoachingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            periodSection
            daysSection
            targetSection
            startDateSection
            saveSection
        }
        .navigationTitle("코칭 목표 설정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("닫기") { dismiss() }
            }
        }
    }

    private var periodSection: some View {
        Section("기간") {
            Picker("기간", selection: $viewModel.selectedPeriod) {
                ForEach(viewModel.periodOptions) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.selectedPeriod.periodType == "custom" {
                TextField("주 단위 기간", text: $viewModel.customWeeksText)
                    .keyboardType(.numberPad)
            }
        }
    }

    private var daysSection: some View {
        Section("러닝 요일") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(viewModel.dayOptions) { option in
                    Button {
                        viewModel.toggleDay(option.value)
                    } label: {
                        Text(option.title)
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(viewModel.selectedDays.contains(option.value) ? NeoStrideColors.accent : NeoStrideColors.surface)
                            .foregroundStyle(viewModel.selectedDays.contains(option.value) ? NeoStrideColors.background : NeoStrideColors.primaryText)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var targetSection: some View {
        Section("목표") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("목표 거리")
                    Spacer()
                    Text(String(format: "%.1f km", viewModel.selectedDistanceKm))
                        .foregroundStyle(NeoStrideColors.secondaryText)
                }
                Slider(value: $viewModel.selectedDistanceKm, in: 1...42, step: 0.5)
                    .tint(NeoStrideColors.accent)
            }

            Stepper(value: $viewModel.selectedPaceMinutes, in: 3...12) {
                HStack {
                    Text("페이스 분")
                    Spacer()
                    Text("\(viewModel.selectedPaceMinutes)분")
                        .foregroundStyle(NeoStrideColors.secondaryText)
                }
            }

            Stepper(value: $viewModel.selectedPaceSeconds, in: 0...55, step: 5) {
                HStack {
                    Text("페이스 초")
                    Spacer()
                    Text("\(viewModel.selectedPaceSeconds)초")
                        .foregroundStyle(NeoStrideColors.secondaryText)
                }
            }
        }
    }

    private var startDateSection: some View {
        Section("시작일") {
            DatePicker("시작일", selection: $viewModel.startDate, displayedComponents: .date)
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                Task {
                    await viewModel.createGoal()
                    if viewModel.errorMessage == nil {
                        dismiss()
                    }
                }
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("목표 생성")
                }
            }
            .buttonStyle(NeoStridePrimaryButtonStyle())
            .disabled(viewModel.isSaving)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(NeoStrideColors.warning)
            }
        }
    }
}
