import Combine
import Foundation

@MainActor
final class RecordsViewModel: ObservableObject {
    @Published private(set) var selectedMonth: RecordsMonth
    @Published private(set) var records: [RunningRecord] = []
    @Published private(set) var selectedRecord: RunningRecord?
    @Published private(set) var isLoading = false
    @Published private(set) var isDetailLoading = false
    @Published var errorMessage: String?

    private let recordsService: RecordsService
    private let authStore: AuthStore

    init(recordsService: RecordsService, authStore: AuthStore, initialMonth: RecordsMonth = RecordsMonth.current()) {
        self.recordsService = recordsService
        self.authStore = authStore
        self.selectedMonth = initialMonth
    }

    func loadMonthlyRecords() async {
        guard let userId = authStore.userId else {
            errorMessage = "사용자 정보를 찾을 수 없습니다."
            return
        }

        let requestedMonth = selectedMonth
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let responses = try await recordsService.fetchUserRecords(userId: userId)
            let mapped = responses.map(RunningRecord.init(response:))
            guard selectedMonth == requestedMonth else { return }
            records = mapped
                .filter { $0.isInMonth(requestedMonth) }
                .sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        } catch {
            errorMessage = "러닝 기록을 불러오지 못했습니다."
        }
    }

    func moveMonth(by offset: Int) async {
        selectedMonth.move(by: offset)
        await loadMonthlyRecords()
    }

    func recordForDetail(base record: RunningRecord) -> RunningRecord {
        if selectedRecord?.id == record.id {
            return selectedRecord ?? record
        }
        return record
    }

    func loadDetail(for record: RunningRecord) async {
        selectedRecord = nil
        isDetailLoading = true
        errorMessage = nil
        defer { isDetailLoading = false }

        do {
            let response = try await recordsService.fetchRecordDetail(recordId: record.id)
            selectedRecord = RunningRecord(response: response)
        } catch {
            errorMessage = "러닝 기록 상세를 불러오지 못했습니다."
            selectedRecord = record
        }
    }
}

extension RecordsMonth {
    static func current(calendar: Calendar = .current, date: Date = Date()) -> RecordsMonth {
        let components = calendar.dateComponents([.year, .month], from: date)
        return RecordsMonth(year: components.year ?? 2026, month: components.month ?? 1)
    }
}
