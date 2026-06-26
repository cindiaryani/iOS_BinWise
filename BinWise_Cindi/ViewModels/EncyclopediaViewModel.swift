import Foundation

/// Drives EncyclopediaView: filters and searches the WasteKnowledgeBase.
/// Pure logic layer — no SwiftUI imports required.
@MainActor
final class EncyclopediaViewModel: ObservableObject {

    // MARK: – Published state

    /// Live search query bound to the search bar.
    @Published var searchText: String = ""
    /// Active category filter; nil = show all categories.
    @Published var selectedCategory: WasteCategory? = nil

    // MARK: – Derived

    /// Items matching the current search + category filter.
    var filteredItems: [WasteKnowledgeItem] {
        var items = WasteKnowledgeBase.items
        if let cat = selectedCategory {
            items = items.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            items = items.filter {
                $0.nameEN.lowercased().contains(q) ||
                $0.nameCN.contains(searchText) ||
                $0.explanation.lowercased().contains(q) ||
                $0.tips.lowercased().contains(q)
            }
        }
        return items
    }

    /// Items flagged as China-specific tricky cases (shown in the highlighted section).
    var trickyItems: [WasteKnowledgeItem] {
        WasteKnowledgeBase.items.filter { $0.isTricky }
    }

    /// True when the tricky section should appear (no filter, empty search).
    var showTrickySection: Bool {
        selectedCategory == nil && searchText.isEmpty
    }

    // MARK: – Actions

    /// Clears both search text and category filter.
    func clearFilters() {
        searchText       = ""
        selectedCategory = nil
    }
}
