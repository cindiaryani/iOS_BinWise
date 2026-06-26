import SwiftUI

// MARK: – Tab definition

private enum AppTab: Int, CaseIterable {
    case home, learn, scan, impact, profile
}

// MARK: – LearnView (sub-tabs: Quiz + Encyclopedia + Chat)

struct LearnView: View {
    @Environment(\.appLanguage) var language
    @State private var selected = 0

    var body: some View {
        NavigationStack {
            ZStack {
                DS.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: DS.Spacing.lg) {
                        learnPicker
                        if selected == 0 {
                            learnCards
                        } else if selected == 1 {
                            encyclopediaLink
                        } else {
                            chatLink
                        }
                    }
                    .padding(DS.Spacing.md)
                    .padding(.bottom, 90)
                }
            }
            .navigationTitle(language.text("Learn", "学习"))
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var learnPicker: some View {
        Picker("", selection: $selected) {
            Text(language.text("Quiz", "测验")).tag(0)
            Text(language.text("Encyclopedia", "百科")).tag(1)
            Text(language.text("Chat Coach", "AI对话")).tag(2)
        }
        .pickerStyle(.segmented)
    }

    private var learnCards: some View {
        VStack(spacing: DS.Spacing.md) {
            NavigationLink { QuizView() } label: {
                learnCardLabel(
                    icon: "questionmark.square.fill",
                    color: DS.Category.recyclable,
                    title: language.text("Waste Sorting Quiz", "垃圾分类测验"),
                    subtitle: language.text("Test your knowledge", "测试你的分类知识")
                )
            }

            NavigationLink { MyProgressView() } label: {
                learnCardLabel(
                    icon: "chart.line.uptrend.xyaxis",
                    color: DS.brandAmberDeep,
                    title: language.text("📈 My Progress", "📈 我的进度"),
                    subtitle: language.text("This week vs last week", "本周对比上周")
                )
            }

            DailyChallengeCard()
        }
    }

    private var encyclopediaLink: some View {
        VStack(spacing: DS.Spacing.md) {
            NavigationLink { EncyclopediaView() } label: {
                learnCardLabel(
                    icon: "books.vertical.fill",
                    color: DS.Category.kitchen,
                    title: language.text("Waste Encyclopedia", "垃圾百科"),
                    subtitle: language.text("\(WasteKnowledgeBase.items.count) items inside", "共\(WasteKnowledgeBase.items.count)条目")
                )
            }
            ItemOfTheDayCard()
            EncyclopediaStatsCard()
        }
    }

    private var chatLink: some View {
        VStack(spacing: DS.Spacing.md) {
            NavigationLink { CoachChatView() } label: {
                learnCardLabel(
                    icon: "bubble.left.and.bubble.right.fill",
                    color: DS.brandCharcoal,
                    title: language.text("Chat with AI Coach", "与AI教练对话"),
                    subtitle: language.text("Ask me anything", "问我任何问题")
                )
            }
            AskAboutCard()
        }
    }

    private func learnCardLabel(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(DS.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(DS.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(DS.border)
        }
        .padding(DS.Spacing.md)
        .frame(height: 80)
        .cardStyle()
    }
}

// MARK: – MainTabView

struct MainTabView: View {
    @Environment(\.appLanguage) var language
    @State private var selectedTab: AppTab = .home
    @State private var showCamera = false

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .ignoresSafeArea(edges: .bottom)

            floatingNavBar
        }
        .fullScreenCover(isPresented: $showCamera) {
            NavigationStack {
                LiveCameraContainerView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                showCamera = false
                            } label: {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                            }
                        }
                    }
            }
        }
    }

    // MARK: – Tab content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:    HomeView()
        case .learn:   LearnView()
        case .scan:    Color.clear
        case .impact:  NavigationStack { ImpactView() }
        case .profile: ProfileView()
        }
    }

    // MARK: – Floating capsule nav bar

    private var floatingNavBar: some View {
        ZStack {
            HStack(spacing: 0) {
                tabButton(.home,  icon: "house.fill",       label: language.text("Home", "首页"))
                tabButton(.learn, icon: "book.fill",         label: language.text("Learn", "学习"))
                Color.clear.frame(width: 64) // center camera gap
                tabButton(.impact,  icon: "leaf.fill",       label: language.text("Impact", "贡献"))
                tabButton(.profile, icon: "person.fill",     label: language.text("Profile", "我的"))
            }
            .padding(.horizontal, DS.Spacing.sm)
            .frame(height: 64)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .background(
                Capsule()
                    .fill(DS.bgCard.opacity(0.55))
            )
            .overlay(
                Capsule()
                    .stroke(DS.borderLight, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 6)
            .frame(width: UIScreen.main.bounds.width * 0.85)

            // Floating center camera button — elevated above the pill
            Button {
                showCamera = true
            } label: {
                ZStack {
                    Circle()
                        .fill(DS.brandAmber)
                        .frame(width: 56, height: 56)
                        .shadow(color: DS.brandAmber.opacity(0.5), radius: 14, x: 0, y: 6)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -22)
        }
        .padding(.bottom, 12)
    }

    private func tabButton(_ tab: AppTab, icon: String, label: String) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? DS.brandCharcoal : DS.textTertiary)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isSelected ? DS.brandCharcoal : DS.textTertiary)
                Circle()
                    .fill(isSelected ? DS.brandAmber : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: – Daily Challenge card (Section G)

/// "Item of the day" — first tricky WasteKnowledgeBase item, rotated by weekday.
/// Answer directly on the Learn screen, no navigation needed.
struct DailyChallengeCard: View {
    @Environment(\.appLanguage) var language
    @State private var selected: WasteCategory?
    @State private var answered = false

    private var item: WasteKnowledgeItem? {
        let tricky = WasteKnowledgeBase.items.filter(\.isTricky)
        guard !tricky.isEmpty else { return nil }
        let weekday = Calendar.current.component(.weekday, from: Date())
        return tricky[weekday % tricky.count]
    }

    var body: some View {
        if let item {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Label(language.text("🔥 Daily Challenge", "🔥 每日挑战"),
                      systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundColor(DS.brandAmberDeep)

                Text(language.text(item.nameEN, item.nameCN))
                    .font(.title3.weight(.bold))
                    .foregroundColor(DS.textPrimary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.sm) {
                    ForEach(WasteCategory.allCases, id: \.self) { cat in
                        answerChip(cat: cat, item: item)
                    }
                }

                if answered {
                    Text(selected == item.category
                         ? language.text("✅ Correct! \(item.explanation)", "✅ 答对了！\(item.explanation)")
                         : language.text("❌ Not quite — it's \(item.category.englishName).", "❌ 不对哦——正确答案是\(item.category.chineseName)。"))
                        .font(.caption)
                        .foregroundColor(selected == item.category ? DS.statusSuccess : DS.statusError)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(DS.Spacing.md)
            .background(DS.brandAmberTint)
            .cornerRadius(DS.Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.brandAmberLight, lineWidth: 1)
            )
        }
    }

    private func answerChip(cat: WasteCategory, item: WasteKnowledgeItem) -> some View {
        let isSelected = selected == cat
        return Button {
            guard !answered else { return }
            selected = cat
            answered = true
        } label: {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: cat.iconName)
                    .font(.caption)
                Text(language.text(cat.englishName, cat.chineseName))
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.sm)
            .foregroundColor(answered ? (cat == item.category ? DS.statusSuccess : DS.textTertiary) : DS.textPrimary)
            .background(DS.bgCard)
            .cornerRadius(DS.Radius.control)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.control)
                    .stroke(answered && cat == item.category ? DS.statusSuccess : (isSelected ? DS.brandAmber : DS.borderLight),
                            lineWidth: answered && cat == item.category ? 2 : 1)
            )
        }
        .disabled(answered)
    }
}

// MARK: – Item of the Day card (Section: Encyclopedia liveliness)

/// Highlights one WasteKnowledgeBase item per day, rotated by weekday.
struct ItemOfTheDayCard: View {
    @Environment(\.appLanguage) var language

    private var item: WasteKnowledgeItem? {
        let items = WasteKnowledgeBase.items
        guard !items.isEmpty else { return nil }
        let weekday = Calendar.current.component(.weekday, from: Date())
        return items[weekday % items.count]
    }

    var body: some View {
        if let item {
            NavigationLink {
                WasteKnowledgeDetailView(item: item)
            } label: {
                HStack(spacing: DS.Spacing.md) {
                    Image(systemName: item.category.iconName)
                        .font(.title)
                        .foregroundColor(item.category.color)
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text(language.text("📖 Item of the Day", "📖 今日条目"))
                            .font(.headline)
                            .foregroundColor(DS.textPrimary)
                        Text(language.text(item.nameEN, item.nameCN))
                            .font(.caption)
                            .foregroundColor(DS.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(DS.border)
                }
                .padding(DS.Spacing.md)
                .frame(height: 80)
                .cardStyle()
            }
        }
    }
}

// MARK: – Encyclopedia stats card

struct EncyclopediaStatsCard: View {
    @Environment(\.appLanguage) var language

    private var trickyCount: Int { WasteKnowledgeBase.items.filter(\.isTricky).count }

    var body: some View {
        HStack(spacing: DS.Spacing.lg) {
            statColumn(value: "\(WasteKnowledgeBase.items.count)", label: language.text("Items", "条目"), icon: "books.vertical.fill")
            Divider().frame(height: 32)
            statColumn(value: "\(WasteCategory.allCases.count)", label: language.text("Categories", "分类"), icon: "square.grid.2x2.fill")
            Divider().frame(height: 32)
            statColumn(value: "\(trickyCount)", label: language.text("Tricky Cases", "易错案例"), icon: "brain.head.profile")
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private func statColumn(value: String, label: String, icon: String) -> some View {
        VStack(spacing: DS.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(DS.brandAmberDeep)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(DS.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(DS.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: – Ask About… quick topics card (Section: Coach Chat liveliness)

/// Tappable topic shortcuts that open the chat with the question pre-filled and auto-sent.
struct AskAboutCard: View {
    @Environment(\.appLanguage) var language

    private var topics: [(emoji: String, en: String, cn: String)] {
        [
            ("🔋", "Where does a dead battery go?", "废电池怎么分类？"),
            ("🧻", "Is a used tissue recyclable?", "用过的纸巾可以回收吗？"),
            ("🍱", "How do I sort a greasy takeout box?", "油腻的外卖盒怎么分类？"),
            ("🦴", "Do bones go in kitchen waste?", "骨头属于厨余垃圾吗？"),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text(language.text("🧠 Ask About…", "🧠 快速提问"))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DS.textPrimary)
                .padding(.horizontal, DS.Spacing.xs)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.sm) {
                ForEach(topics, id: \.en) { topic in
                    NavigationLink {
                        CoachChatView(initialQuestion: language.text(topic.en, topic.cn))
                    } label: {
                        VStack(spacing: DS.Spacing.xs) {
                            Text(topic.emoji).font(.title3)
                            Text(language.text(topic.en, topic.cn))
                                .font(.caption2.weight(.medium))
                                .foregroundColor(DS.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(DS.Spacing.md)
                        .frame(height: 80)
                        .background(DS.brandAmberTint)
                        .cornerRadius(DS.Radius.control)
                        .overlay(RoundedRectangle(cornerRadius: DS.Radius.control).stroke(DS.brandAmberLight, lineWidth: 1))
                    }
                }
            }
        }
    }
}
