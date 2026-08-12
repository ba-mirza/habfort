import Foundation

@MainActor
@Observable
final class HistoryViewModel {
    struct DayGroup: Identifiable {
        let day: Date
        let entries: [HabitHistoryEntry]
        var id: Date { day }
    }

    // Matches the backend's default page size (ListHistoryQueryDto.take).
    private let pageSize = 20

    private(set) var entries: [HabitHistoryEntry] = []
    private(set) var stats: HistoryStats?
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    /// False once a page comes back short — that's the last page.
    private(set) var canLoadMore = true
    var errorMessage: String?

    var statusFilter: HabitHistoryStatus?
    var typeFilter: HabitType?

    /// Entries arrive newest-first, so grouping preserves that order within
    /// each day and the day keys only need sorting descending.
    var dayGroups: [DayGroup] {
        Dictionary(grouping: entries) { ISO8601.day(from: $0.endedAt) ?? .distantPast }
            .map { DayGroup(day: $0.key, entries: $0.value) }
            .sorted { $0.day > $1.day }
    }

    func load(apiClient: APIClient) async {
        isLoading = true
        errorMessage = nil
        do {
            async let entriesTask: [HabitHistoryEntry] = apiClient.get(historyPath(skip: 0))
            async let statsTask: HistoryStats = apiClient.get("/history/stats")
            let (fetchedEntries, fetchedStats) = try await (entriesTask, statsTask)
            entries = fetchedEntries
            stats = fetchedStats
            canLoadMore = fetchedEntries.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore(apiClient: APIClient) async {
        guard canLoadMore, !isLoading, !isLoadingMore else { return }
        isLoadingMore = true
        do {
            let page: [HabitHistoryEntry] = try await apiClient.get(historyPath(skip: entries.count))
            // A concurrent completion can push an already-loaded entry onto the
            // next page; drop duplicates so ForEach ids stay unique.
            let known = Set(entries.map(\.id))
            entries += page.filter { !known.contains($0.id) }
            canLoadMore = page.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingMore = false
    }

    func applyFilters(apiClient: APIClient) async {
        entries = []
        canLoadMore = true
        await load(apiClient: apiClient)
    }

    private func historyPath(skip: Int) -> String {
        var items = ["take=\(pageSize)", "skip=\(skip)"]
        if let statusFilter {
            items.append("status=\(statusFilter.rawValue)")
        }
        if let typeFilter {
            items.append("type=\(typeFilter.rawValue)")
        }
        return "/history?" + items.joined(separator: "&")
    }
}
