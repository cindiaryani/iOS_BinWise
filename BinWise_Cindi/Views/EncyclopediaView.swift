import SwiftUI

// MARK: – Encyclopedia root view

/// Browseable, searchable knowledge base of 60 China-specific waste items.
struct EncyclopediaView: View {

    @StateObject private var vm = EncyclopediaViewModel()
    @Environment(\.appLanguage) var language

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.top, DS.Spacing.sm)
                    .padding(.bottom, DS.Spacing.xs)
                categoryFilterRow
                    .padding(.bottom, DS.Spacing.sm)
                itemList
            }
        }
        .navigationTitle(language.text("Encyclopedia", "垃圾百科"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    CategoryDemoView()
                } label: {
                    Label(language.text("How to Sort", "如何分类"),
                          systemImage: "play.rectangle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(DS.primary)
                }
            }
        }
    }

    // MARK: – Search bar

    private var searchBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(vm.searchText.isEmpty ? DS.textSecondary : DS.primary)
            TextField(language.text("Search items…", "搜索垃圾分类"), text: $vm.searchText)
                .autocorrectionDisabled()
            if !vm.searchText.isEmpty {
                Button { vm.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DS.textSecondary)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(DS.surface)
        .cornerRadius(DS.Radius.control)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.control)
                .stroke(vm.searchText.isEmpty ? DS.border : DS.primary, lineWidth: 1.5)
        )
        .accessibilityLabel("Search waste items")
    }

    // MARK: – Category filter pills

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.sm) {
                filterPill(label: language.text("All", "全部"), category: nil, icon: "square.grid.2x2")
                ForEach(WasteCategory.allCases, id: \.self) { cat in
                    filterPill(label: language.text(cat.englishName, cat.chineseName),
                               category: cat, icon: cat.iconName)
                }
            }
            .padding(.horizontal, DS.Spacing.lg)
        }
    }

    private func filterPill(label: String, category: WasteCategory?, icon: String) -> some View {
        let selected = vm.selectedCategory == category
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                vm.selectedCategory = selected ? nil : category
            }
        } label: {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(selected ? .white : (category?.color ?? DS.primary))
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, 6)
            .background(selected ? (category?.color ?? DS.primary) : DS.surface)
            .cornerRadius(DS.Radius.badge)
            .overlay(
                Capsule()
                    .stroke(selected ? .clear : (category?.color ?? DS.primary).opacity(0.35),
                            lineWidth: 1)
            )
        }
        .accessibilityLabel(category == nil ? "Show all categories" : "Filter by \(label)")
    }

    // MARK: – Main list

    @ViewBuilder
    private var itemList: some View {
        if vm.filteredItems.isEmpty {
            emptyState
        } else {
            List {
                if vm.showTrickySection {
                    trickyCasesSection
                }
                Section {
                    ForEach(vm.filteredItems) { item in
                        NavigationLink {
                            WasteKnowledgeDetailView(item: item)
                        } label: {
                            WasteKnowledgeItemRow(item: item)
                        }
                        .listRowBackground(DS.surface)
                        .listRowSeparatorTint(DS.border)
                    }
                } header: {
                    let count = vm.filteredItems.count
                    Text(language.text(
                        "\(count) \(count == 1 ? "item" : "items")",
                        "\(count)项"
                    ))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(DS.textSecondary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 90) }
        }
    }

    // MARK: – Tricky cases section

    private var trickyCasesSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.sm) {
                    ForEach(vm.trickyItems) { item in
                        NavigationLink {
                            WasteKnowledgeDetailView(item: item)
                        } label: {
                            TrickyItemCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, DS.Spacing.xs)
                .padding(.horizontal, DS.Spacing.xs)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            .listRowBackground(DS.background)
            .listRowSeparator(.hidden)
        } header: {
            HStack {
                Image(systemName: "brain.head.profile").foregroundColor(.orange)
                Text(language.text("Tricky Cases", "易错案例"))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(DS.textSecondary)
            }
        }
    }

    // MARK: – Empty state

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 56))
                .foregroundColor(DS.border)
            Text(language.text("No items found", "未找到相关结果"))
                .font(.headline)
                .foregroundColor(DS.textSecondary)
            Button { vm.clearFilters() } label: {
                Text(language.text("Clear filters", "清除筛选"))
                    .font(.subheadline)
                    .foregroundColor(DS.primary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: – Item row

/// Compact list row showing category colour dot, EN + CN names, and tricky badge.
struct WasteKnowledgeItemRow: View {
    let item: WasteKnowledgeItem
    @Environment(\.appLanguage) var language

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Circle()
                .fill(item.category.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(language.text(item.nameEN, item.nameCN))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(DS.textPrimary)
                if language == .both {
                    Text(item.nameCN)
                        .font(.caption)
                        .foregroundColor(DS.textSecondary)
                }
            }

            Spacer()

            if item.isTricky {
                Text(language.text("⚠️ Tricky", "⚠️ 易错"))
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(DS.Radius.badge)
            }
        }
        .padding(.vertical, DS.Spacing.xs)
        .accessibilityLabel("\(item.nameEN), \(item.nameCN), category: \(item.category.englishName)")
    }
}

// MARK: – Tricky item card (horizontal scroll)

/// Compact card used in the Tricky Cases horizontal scroll.
struct TrickyItemCard: View {
    let item: WasteKnowledgeItem
    @Environment(\.appLanguage) var language

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            HStack {
                Image(systemName: item.category.iconName)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(item.category.color)
                Spacer()
                Text("⚠️")
                    .font(.caption)
            }
            Text(language.text(item.nameEN, item.nameCN))
                .font(.caption.weight(.bold))
                .foregroundColor(DS.textPrimary)
                .lineLimit(2)
            if language == .both {
                Text(item.nameCN)
                    .font(.caption2)
                    .foregroundColor(DS.textSecondary)
            }
        }
        .frame(width: 120)
        .padding(DS.Spacing.sm)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(item.category.color.opacity(0.3), lineWidth: 1)
        )
        .cardShadow()
        .accessibilityLabel("Tricky case: \(item.nameEN)")
    }
}

// MARK: – Detail view

/// Full detail screen for a single WasteKnowledgeItem.
struct WasteKnowledgeDetailView: View {
    let item: WasteKnowledgeItem
    @Environment(\.appLanguage) var language

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    categoryBadge
                    nameHeader
                    if item.isTricky { trickyBanner }
                    whySection
                    if let mistake = item.commonMistake { mistakeSection(mistake) }
                    tipSection
                    didYouKnowSection
                }
                .padding(DS.Spacing.lg)
                .padding(.bottom, 90)
            }
        }
        .navigationTitle(language.text(item.nameEN, item.nameCN))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: – Category badge

    private var categoryBadge: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: item.category.iconName)
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 0) {
                Text(language.text(item.category.englishName, item.category.chineseName))
                    .font(.headline)
                    .foregroundColor(.white)
                if language == .both {
                    Text(item.category.englishName)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            Spacer()
        }
        .padding(DS.Spacing.md)
        .background(item.category.color)
        .cornerRadius(DS.Radius.card)
    }

    // MARK: – Name header

    private var nameHeader: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(language.text(item.nameEN, item.nameCN))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(DS.textPrimary)
            if language == .both {
                Text(item.nameCN)
                    .font(.title3.weight(.medium))
                    .foregroundColor(DS.textSecondary)
            }
        }
    }

    // MARK: – Tricky banner

    private var trickyBanner: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.orange)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(language.text("China Tricky Case", "易错案例"))
                    .font(.caption.weight(.bold))
                    .foregroundColor(.orange)
                Text(language.text(
                    "This item has China-specific rules that often differ from other countries.",
                    "该物品在中国有特殊分类规则，与其他国家不同。"
                ))
                .font(.caption)
                .foregroundColor(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DS.Spacing.md)
        .background(Color.orange.opacity(0.10))
        .cornerRadius(DS.Radius.card)
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(Color.orange.opacity(0.3), lineWidth: 1))
    }

    // MARK: – Why section

    private var whySection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label(language.text("Why this category?", "为什么这样分类？"),
                  systemImage: "questionmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DS.primary)
            Text(item.explanation)
                .font(.body)
                .foregroundColor(DS.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    // MARK: – Common mistake section

    private func mistakeSection(_ mistake: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label(language.text("Common Mistake", "常见错误"), systemImage: "xmark.octagon.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.red)
            Text(mistake)
                .font(.body)
                .foregroundColor(DS.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .background(Color.red.opacity(0.06))
        .cornerRadius(DS.Radius.card)
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(Color.red.opacity(0.2), lineWidth: 1))
    }

    // MARK: – Tip section

    private var tipSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label(language.text("Disposal Tip", "处理提示"), systemImage: "lightbulb.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DS.primary)
            Text(item.tips)
                .font(.body)
                .foregroundColor(DS.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .background(DS.primary.opacity(0.07))
        .cornerRadius(DS.Radius.card)
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.primary.opacity(0.25), lineWidth: 1))
    }

    // MARK: – Did You Know? (Section G)

    private static let funFacts: [WasteCategory: String] = [
        .recyclable: "China processes over 200 million tons of recyclable materials annually — more than any other country. / 中国每年处理超过2亿吨可回收材料，居世界首位。",
        .hazardous:  "A single AA battery can contaminate 1 square meter of soil for 50 years if landfilled improperly. / 一节五号电池若处理不当，可污染1平方米土地长达50年。",
        .kitchen:    "Wet waste (kitchen scraps) makes up ~50% of household garbage in China's major cities. / 厨余垃圾约占中国大城市家庭垃圾总量的50%。",
        .other:      "Styrofoam takes over 500 years to decompose in landfill. / 泡沫塑料在填埋场中需要500多年才能分解。",
    ]

    private var didYouKnowSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label(language.text("Did You Know?", "你知道吗？"), systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DS.brandAmberDeep)
            Text(Self.funFacts[item.category] ?? "")
                .font(.body)
                .foregroundColor(DS.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .background(DS.brandAmberTint)
        .cornerRadius(DS.Radius.card)
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.brandAmberLight, lineWidth: 1))
    }
}

// MARK: – Previews

struct EncyclopediaView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EncyclopediaView()
        }
    }
}
