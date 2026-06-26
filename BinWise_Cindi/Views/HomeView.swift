import SwiftUI
import Charts

struct HomeView: View {

    @EnvironmentObject var historyStore:  HistoryStore
    @EnvironmentObject var quizStore:     QuizStore
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var authVM:        AuthViewModel
    @Environment(\.appLanguage) var language

    @StateObject private var scanVM = ScanViewModel()
    @StateObject private var coachVM = CoachViewModel()
    @StateObject private var classifier = ClassifierService()

    @State private var capturedImage: UIImage?
    @State private var showSourceDialog = false
    @State private var showCamera       = false
    @State private var showScan         = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    private var streak: Int {
        GamificationService.streak(from: historyStore.records)
    }
    private var totalCO2: Double {
        historyStore.totalCO2()
    }
    private var perCategory: [WasteCategory: Int] {
        Dictionary(grouping: historyStore.records, by: \.category).mapValues(\.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: DS.Spacing.lg) {
                        Group {
                            ModelStatusBanner(isModelLoaded: classifier.isModelLoaded)
                            headerSection
                            streakBanner
                            dailyTipCard
                        }
                        photoButtons
                        quickStatsStrip
                        thisWeekChart
                        wasteBreakdownChart
                        recentScans
                        coachTipCard
                        discoverGrid
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.bottom, 100) // clear custom tab bar
                }
            }
            .confirmationDialog(
                language.text("Select Image Source", "选择图片来源"),
                isPresented: $showSourceDialog,
                titleVisibility: .visible
            ) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button(language.text("Take Photo", "拍照")) {
                        sourceType = .camera; showCamera = true
                    }
                }
                Button(language.text("Choose from Library", "从相册选择")) {
                    sourceType = .photoLibrary; showCamera = true
                }
                Button(language.text("Cancel", "取消"), role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showCamera, onDismiss: {
                guard let img = capturedImage else { return }
                capturedImage = nil
                scanVM.process(image: img)
                showScan = true
            }) {
                CameraPicker(image: $capturedImage, sourceType: sourceType)
            }
            .navigationDestination(isPresented: $showScan) {
                ScanView(viewModel: scanVM)
            }
            .onAppear {
                if coachVM.tips.isEmpty {
                    Task { await coachVM.load(historyStore: historyStore, quizStore: quizStore) }
                }
            }
        }
    }

    // MARK: – 1. Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: DS.Spacing.md) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(greetingText)
                    .font(.subheadline)
                    .foregroundColor(DS.textSecondary)
                Text(displayName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DS.textPrimary)
            }
            Spacer()
            avatarCircle
        }
        .padding(.top, DS.Spacing.md)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return language.text("Good morning", "早上好")
        case 12..<17: return language.text("Good afternoon", "下午好")
        default: return language.text("Good evening", "晚上好")
        }
    }

    private var displayName: String {
        if let profile = authVM.user { return profile.firstNameOrEmail }
        return authVM.isGuest ? language.text("Guest", "访客") : "BinWise"
    }

    private var avatarCircle: some View {
        ZStack {
            Circle()
                .fill(DS.tealGradient)
                .frame(width: 44, height: 44)
            Text(avatarInitials)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private var avatarInitials: String {
        if let profile = authVM.user { return profile.initials }
        return authVM.isGuest ? "G" : "B"
    }

    // MARK: – 2. Streak banner

    private var streakBanner: some View {
        VStack(spacing: DS.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    HStack(spacing: DS.Spacing.xs) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text(language.text("\(streak)-day streak!", "\(streak)天连续记录！"))
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                    }
                    Text(language.text("Keep sorting every day", "每天坚持分类垃圾"))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Text("🔥")
                    .font(.system(size: 36))
            }
            weekCalendar
        }
        .padding(DS.Spacing.md)
        .background(DS.tealGradient)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    private var weekCalendar: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let recordDays = Set(historyStore.records.map { calendar.startOfDay(for: $0.date) })
        let weekdays = (0..<7).map { i in
            calendar.date(byAdding: .day, value: i - 6, to: today)!
        }
        let dayLetters: [String] = {
            switch language {
            case .english: return ["M","T","W","T","F","S","S"]
            case .chinese: return ["一","二","三","四","五","六","日"]
            case .both:    return ["M","T","W","T","F","S","S"]
            }
        }()
        let weekdaySymbols = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

        return HStack(spacing: 0) {
            ForEach(Array(weekdays.enumerated()), id: \.offset) { idx, day in
                let weekdayIdx = calendar.component(.weekday, from: day) - 1
                let letterIdx = weekdayIdx == 0 ? 6 : weekdayIdx - 1
                let hasRecord = recordDays.contains(day)
                let isToday = calendar.isDateInToday(day)
                let _ = weekdaySymbols[weekdayIdx]

                VStack(spacing: DS.Spacing.xs) {
                    Text(dayLetters[safe: letterIdx] ?? "")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    ZStack {
                        Circle()
                            .fill(hasRecord ? Color.white : Color.white.opacity(0.2))
                            .frame(width: 28, height: 28)
                        if hasRecord {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(DS.primary)
                        } else if isToday {
                            Circle()
                                .stroke(Color.white, lineWidth: 1.5)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: – Daily Tip card (Section G)

    private static let dailyTips: [(en: String, cn: String)] = [
        ("China's 4-bin system has reduced landfill waste by over 30% in pilot cities.",
         "中国的四分类系统已使试点城市的垃圾填埋量减少超过30%。"),
        ("Rinsing recyclables before sorting increases their recycling value significantly.",
         "回收前清洗可回收物能大幅提升其回收价值。"),
        ("Used tissues are Other Trash — they're contaminated and can't be recycled.",
         "用过的纸巾属于其他垃圾——已被污染，无法回收。"),
        ("Expired batteries are Hazardous Waste — never throw them in regular bins.",
         "过期电池属于有害垃圾——切勿投入普通垃圾桶。"),
        ("Greasy pizza boxes go to Other Trash, but the clean lid can be recycled.",
         "油腻的披萨盒属于其他垃圾，但干净的盒盖可以回收。"),
        ("Kitchen waste composted properly can become fertilizer in just weeks.",
         "厨余垃圾经妥善堆肥后，几周内即可变成肥料。"),
        ("Shanghai was the first Chinese city to make waste sorting mandatory, in 2019.",
         "上海是中国首个于2019年强制推行垃圾分类的城市。"),
    ]

    private var dailyTipCard: some View {
        let weekday = Calendar.current.component(.weekday, from: Date()) - 1
        let tip = Self.dailyTips[weekday % Self.dailyTips.count]
        return HStack(alignment: .top, spacing: DS.Spacing.md) {
            Rectangle()
                .fill(DS.brandAmber)
                .frame(width: 4)
                .cornerRadius(2)
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Label(language.text("Daily Tip", "今日小贴士"), systemImage: "lightbulb.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(DS.brandAmberDeep)
                Text(language.text(tip.en, tip.cn))
                    .font(.caption)
                    .foregroundColor(DS.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.brandAmberTint)
        .cornerRadius(DS.Radius.card)
    }

    // MARK: – This Week mini chart (Section G)

    private var thisWeekSeries: [(day: String, count: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let symbols = ["S", "M", "T", "W", "T", "F", "S"]
        return (0..<7).map { i in
            let day = cal.date(byAdding: .day, value: i - 6, to: today)!
            let weekdayIdx = cal.component(.weekday, from: day) - 1
            let count = historyStore.records.filter { cal.isDate($0.date, inSameDayAs: day) }.count
            return (day: symbols[weekdayIdx], count: count)
        }
    }

    private var thisWeekChart: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            DS.sectionHeader(language.text("This Week", "本周统计"))
            Chart(Array(thisWeekSeries.enumerated()), id: \.offset) { _, point in
                BarMark(
                    x: .value("Day", point.day),
                    y: .value("Items", point.count)
                )
                .foregroundStyle(DS.brandAmber)
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks { AxisValueLabel().foregroundStyle(DS.textSecondary) }
            }
            .chartYAxis(.hidden)
            .frame(height: 90)
            .padding(DS.Spacing.md)
            .cardStyle()
        }
    }

    // MARK: – Photo / Gallery buttons

    private var photoButtons: some View {
        HStack(spacing: DS.Spacing.sm) {
            Button {
                sourceType = .camera
                scanVM.reset()
                showScan = false
                showCamera = true
            } label: {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "camera.fill")
                        .font(.subheadline.weight(.semibold))
                    Text(language.text("Take Photo", "拍照"))
                        .font(.subheadline.weight(.medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.md)
                .background(DS.tealGradient)
                .cornerRadius(DS.Radius.control)
            }

            Button {
                sourceType = .photoLibrary
                scanVM.reset()
                showScan = false
                showCamera = true
            } label: {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.subheadline.weight(.semibold))
                    Text(language.text("From Gallery", "从相册"))
                        .font(.subheadline.weight(.medium))
                }
                .foregroundColor(DS.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.md)
                .background(DS.surface)
                .cornerRadius(DS.Radius.control)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.control)
                    .stroke(DS.primary.opacity(0.4), lineWidth: 1))
            }
        }
    }

    // MARK: – 3. Quick stats strip

    private var quickStatsStrip: some View {
        HStack(spacing: DS.Spacing.sm) {
            statCard(
                value: "\(historyStore.records.count)",
                label: language.text("Items Sorted", "已分类"),
                icon: "checkmark.circle.fill",
                color: DS.success
            )
            statCard(
                value: String(format: "%.2f", totalCO2) + " kg",
                label: language.text("CO₂ Saved", "碳减排"),
                icon: "leaf.fill",
                color: DS.primary
            )
            statCard(
                value: "\(GamificationService.badges(from: historyStore.records, quizStats: quizStore.stats).filter(\.unlocked).count)",
                label: language.text("Badges", "成就"),
                icon: "star.fill",
                color: .orange
            )
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: DS.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(DS.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DS.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.md)
        .cardStyle()
    }

    // MARK: – 4. Waste breakdown donut chart (Canvas — iOS 15+)

    private var wasteBreakdownChart: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            DS.sectionHeader(language.text("Waste Breakdown", "垃圾分类统计"))

            if historyStore.records.isEmpty {
                emptyChartPlaceholder
            } else {
                HStack(alignment: .center, spacing: DS.Spacing.lg) {
                    DonutChartView(data: perCategory)
                        .frame(width: 120, height: 120)
                    legendView
                }
                .padding(DS.Spacing.md)
                .cardStyle()
            }
        }
    }

    private var emptyChartPlaceholder: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: "chart.pie")
                .font(.title)
                .foregroundColor(DS.border)
            Text(language.text("Sort some waste to see your breakdown.",
                               "开始分类垃圾后，将显示统计图表。"))
                .font(.caption)
                .foregroundColor(DS.textSecondary)
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            ForEach(WasteCategory.allCases, id: \.self) { cat in
                let count = perCategory[cat] ?? 0
                HStack(spacing: DS.Spacing.sm) {
                    Circle()
                        .fill(cat.color)
                        .frame(width: 10, height: 10)
                    Text(language.text(cat.englishName, cat.chineseName))
                        .font(.caption)
                        .foregroundColor(DS.textPrimary)
                    Spacer()
                    Text("\(count)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(DS.textSecondary)
                }
            }
        }
    }

    // MARK: – 5. Recent scans

    private var recentScans: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                DS.sectionHeader(language.text("Recent Scans", "最近扫描"))
                Spacer()
                NavigationLink { HistoryView() } label: {
                    Text(language.text("See all", "查看全部"))
                        .font(.caption.weight(.medium))
                        .foregroundColor(DS.primary)
                }
            }

            if historyStore.records.isEmpty {
                Text(language.text("No scans yet. Tap the camera button to start!",
                                   "暂无记录，点击相机按钮开始扫描！"))
                    .font(.caption)
                    .foregroundColor(DS.textSecondary)
                    .padding(DS.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
            } else {
                VStack(spacing: DS.Spacing.xs) {
                    ForEach(historyStore.records.prefix(3)) { record in
                        recentScanRow(record)
                    }
                }
                .cardStyle()
            }
        }
    }

    private func recentScanRow(_ record: ScanRecord) -> some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: record.category.iconName)
                .font(.title3)
                .foregroundColor(record.category.color)
                .frame(width: 36, height: 36)
                .background(record.category.color.opacity(0.1))
                .cornerRadius(DS.Radius.control)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.displayLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(DS.textPrimary)
                    .lineLimit(1)
                Text(language.text(record.category.englishName, record.category.chineseName))
                    .font(.caption)
                    .foregroundColor(record.category.color)
            }
            Spacer()
            Text(record.date, style: .relative)
                .font(.caption2)
                .foregroundColor(DS.textSecondary)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
    }

    // MARK: – 6. Coach tip card

    private var coachTipCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            DS.sectionHeader(language.text("Today's Tip", "今日建议"))

            HStack(alignment: .top, spacing: DS.Spacing.md) {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(DS.primary)
                    .frame(width: 36)
                if coachVM.isLoading {
                    ProgressView()
                        .tint(DS.primary)
                } else if !coachVM.tips.isEmpty {
                    Text(String(coachVM.tips.prefix(180)))
                        .font(.caption)
                        .foregroundColor(DS.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(language.text("Tap to load personalised tips.",
                                       "点击加载个性化建议。"))
                        .font(.caption)
                        .foregroundColor(DS.textSecondary)
                }
                Spacer()
            }
            .padding(DS.Spacing.md)
            .cardStyle()
        }
    }

    // MARK: – 7. Discover grid

    private var discoverGrid: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            DS.sectionHeader(language.text("Discover", "探索"))
            HStack(spacing: DS.Spacing.sm) {
                NavigationLink {
                    BarcodeInputView()
                } label: {
                    discoverTileLabel(
                        icon: "barcode.viewfinder",
                        title: language.text("Barcode Scan", "条形码"),
                        color: DS.Category.other
                    )
                }
                NavigationLink { CoachView() } label: {
                    discoverTileLabel(
                        icon: "sparkles",
                        title: language.text("AI Coach", "AI教练"),
                        color: DS.Category.hazardous
                    )
                }
            }
            HStack(spacing: DS.Spacing.sm) {
                NavigationLink { OCRScanView() } label: {
                    discoverTileLabel(
                        icon: "text.viewfinder",
                        title: language.text("Scan Label", "扫描标签"),
                        color: DS.Category.recyclable
                    )
                }
                NavigationLink { EncyclopediaView() } label: {
                    discoverTileLabel(
                        icon: "books.vertical.fill",
                        title: language.text("Encyclopedia", "垃圾百科"),
                        color: DS.Category.kitchen
                    )
                }
            }
        }
    }

    private func discoverTile(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            discoverTileLabel(icon: icon, title: title, color: color)
        }
    }

    private func discoverTileLabel(icon: String, title: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundColor(color)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DS.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.md)
        .cardStyle()
    }
}

// MARK: – Canvas-based donut chart (iOS 15+, avoids SectorMark which is iOS 17+)

struct DonutChartView: View {
    let data: [WasteCategory: Int]

    private var total: Int { data.values.reduce(0, +) }

    var body: some View {
        Canvas { ctx, size in
            guard total > 0 else { return }
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            let innerRadius = radius * 0.55
            var startAngle = Angle.degrees(-90)

            for cat in WasteCategory.allCases {
                let count = data[cat] ?? 0
                guard count > 0 else { continue }
                let fraction = Double(count) / Double(total)
                let endAngle = startAngle + .degrees(fraction * 360)

                var path = Path()
                path.move(to: center)
                path.addArc(center: center, radius: radius,
                            startAngle: startAngle, endAngle: endAngle,
                            clockwise: false)
                path.closeSubpath()

                var inner = Path()
                inner.addArc(center: center, radius: innerRadius,
                             startAngle: startAngle, endAngle: endAngle,
                             clockwise: false)

                ctx.fill(path, with: .color(cat.color))
                startAngle = endAngle
            }

            // Cut out center hole
            var hole = Path()
            hole.addEllipse(in: CGRect(
                x: center.x - innerRadius,
                y: center.y - innerRadius,
                width: innerRadius * 2,
                height: innerRadius * 2
            ))
            ctx.fill(hole, with: .color(.white))
        }
    }
}

// MARK: – Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(HistoryStore())
            .environmentObject(QuizStore())
            .environmentObject(SettingsStore())
            .environmentObject(AuthViewModel())
    }
}
