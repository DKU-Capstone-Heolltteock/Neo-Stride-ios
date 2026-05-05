import SwiftUI

struct CoachingView: View {
    @StateObject private var viewModel: CoachingViewModel
    @State private var showingGoalSetup = false

    init(viewModel: CoachingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusMessages

                    if viewModel.isLoading && viewModel.activeGoal == nil {
                        loadingState
                    } else if let summary = viewModel.goalSummary {
                        activeGoalCard(summary)
                        todayPlanCard
                        planList
                    } else {
                        emptyState
                    }
                }
                .padding(20)
            }
            .background(NeoStrideColors.background.ignoresSafeArea())
            .navigationTitle("코칭")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingGoalSetup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .sheet(isPresented: $showingGoalSetup) {
                NavigationStack {
                    GoalSettingView(viewModel: viewModel)
                }
            }
        }
    }

    @ViewBuilder
    private var statusMessages: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.footnote)
                .foregroundStyle(NeoStrideColors.warning)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(NeoStrideColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }

        if let successMessage = viewModel.successMessage {
            Text(successMessage)
                .font(.footnote)
                .foregroundStyle(NeoStrideColors.accent)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(NeoStrideColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView("코칭 정보를 불러오는 중...")
                .tint(NeoStrideColors.accent)
            Text("서버의 활성 목표와 오늘 플랜을 확인하고 있습니다.")
                .font(.footnote)
                .foregroundStyle(NeoStrideColors.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 52))
                .foregroundStyle(NeoStrideColors.accent)
            Text("활성 코칭 목표가 없습니다.")
                .font(.title3.bold())
                .foregroundStyle(NeoStrideColors.primaryText)
            Text("기간, 요일, 목표 거리와 페이스를 설정하면 서버에서 날짜별 코칭 플랜을 생성합니다.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(NeoStrideColors.secondaryText)
            Button("코칭 목표 만들기") {
                showingGoalSetup = true
            }
            .buttonStyle(NeoStridePrimaryButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 360)
        .background(NeoStrideColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func activeGoalCard(_ summary: CoachingGoalSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("활성 목표")
                    .font(.headline)
                    .foregroundStyle(NeoStrideColors.primaryText)
                Spacer()
                Text(summary.periodText)
                    .font(.caption.bold())
                    .foregroundStyle(NeoStrideColors.background)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(NeoStrideColors.accent)
                    .clipShape(Capsule())
            }

            Text(summary.targetText)
                .font(.title2.bold())
                .foregroundStyle(NeoStrideColors.primaryText)

            VStack(alignment: .leading, spacing: 6) {
                Label(summary.runningDaysText, systemImage: "calendar")
                Label(summary.dateRangeText, systemImage: "flag.checkered")
            }
            .font(.subheadline)
            .foregroundStyle(NeoStrideColors.secondaryText)

            Button(role: .destructive) {
                Task { await viewModel.deleteActiveGoal() }
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(NeoStrideColors.warning)
                } else {
                    Label("목표 삭제", systemImage: "trash")
                }
            }
            .disabled(viewModel.isSaving)
            .font(.footnote.bold())
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NeoStrideColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var todayPlanCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("오늘의 플랜")
                .font(.headline)
                .foregroundStyle(NeoStrideColors.primaryText)

            if viewModel.todayPlan?.hasPlan == true, let plan = viewModel.todayPlan?.planDay {
                PlanDayRow(plan: plan, prominent: true)
            } else {
                Text("오늘 예정된 코칭 러닝이 없습니다.")
                    .font(.subheadline)
                    .foregroundStyle(NeoStrideColors.secondaryText)
                    .padding(.vertical, 8)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NeoStrideColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var planList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("플랜 일정")
                .font(.headline)
                .foregroundStyle(NeoStrideColors.primaryText)

            if viewModel.planDays.isEmpty {
                Text("아직 생성된 플랜 일정이 없습니다.")
                    .font(.subheadline)
                    .foregroundStyle(NeoStrideColors.secondaryText)
                    .padding(.vertical, 8)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.planDays) { plan in
                        PlanDayRow(plan: plan, prominent: false)
                    }
                }
            }
        }
    }
}

struct PlanDayRow: View {
    let plan: PlanDayResponse
    let prominent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(plan.dateText)
                    .font(prominent ? .headline : .subheadline.bold())
                    .foregroundStyle(NeoStrideColors.primaryText)
                Spacer()
                Text(plan.statusText)
                    .font(.caption.bold())
                    .foregroundStyle(plan.completed ? NeoStrideColors.accent : NeoStrideColors.secondaryText)
            }

            HStack(spacing: 12) {
                Label(plan.distanceText, systemImage: "figure.run")
                Label(plan.paceText, systemImage: "timer")
            }
            .font(.caption)
            .foregroundStyle(NeoStrideColors.secondaryText)

            if let description = plan.description, !description.isEmpty {
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(NeoStrideColors.primaryText)
            }

            if let feedback = plan.aiFeedbackComment, !feedback.isEmpty {
                Text(feedback)
                    .font(.footnote)
                    .foregroundStyle(NeoStrideColors.accent)
                    .padding(.top, 4)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(prominent ? NeoStrideColors.surface.opacity(0.85) : NeoStrideColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
