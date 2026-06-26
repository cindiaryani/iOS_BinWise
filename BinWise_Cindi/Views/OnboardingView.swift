import SwiftUI

struct OnboardingView: View {

    @EnvironmentObject var settingsStore: SettingsStore
    @State private var currentPage = 0

    private var language: AppLanguage { settingsStore.language }

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()

            if currentPage == 0 {
                categoriesPage
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))
            } else {
                featuresPage
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }

    // MARK: – Page 1: The 4 categories

    private var categoriesPage: some View {
        VStack(spacing: DS.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DS.amberGradient)
                    .frame(width: 96, height: 96)
                Image(systemName: "arrow.3.trianglepath")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("BinWise")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(DS.textPrimary)

            Text(language.text("China's 4-Category Waste System", "中国垃圾四分类"))
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(DS.textSecondary)

            VStack(spacing: DS.Spacing.sm) {
                ForEach(WasteCategory.allCases, id: \.self) { cat in
                    categoryRow(cat)
                }
            }
            .padding(.horizontal, DS.Spacing.md)

            pageIndicator(active: 0)

            Spacer()

            Button { currentPage = 1 } label: {
                Text(language.text("Next →", "下一步 →"))
                    .primaryButtonStyle()
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.bottom, DS.Spacing.xl)
        }
    }

    private func categoryRow(_ cat: WasteCategory) -> some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: cat.iconName)
                .font(.title3)
                .foregroundColor(cat.color)
                .frame(width: 36)
            Text(language.text(cat.englishName, cat.chineseName))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DS.textPrimary)
            Spacer()
            Text(cat.chineseName)
                .font(.caption)
                .foregroundColor(cat.color)
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xs)
                .background(cat.color.opacity(0.12))
                .cornerRadius(DS.Radius.badge)
        }
        .padding(DS.Spacing.md)
        .background(DS.surface)
        .cornerRadius(DS.Radius.control)
        .cardShadow()
    }

    // MARK: – Page 2: Features

    private var featuresPage: some View {
        VStack(spacing: DS.Spacing.lg) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(DS.primary)

            Text(language.text("How It Works", "功能介绍"))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(DS.textPrimary)

            VStack(spacing: DS.Spacing.md) {
                featureRow(icon: "camera.viewfinder", color: DS.primary,
                           title: language.text("Live Scan", "实时扫描"),
                           body: language.text("Point your camera — AI auto-classifies.",
                                               "对准物品，AI自动识别分类。"))
                featureRow(icon: "leaf.fill", color: DS.success,
                           title: language.text("Impact Tracker", "贡献追踪"),
                           body: language.text("See your cumulative CO₂ savings.",
                                               "查看你的累积碳减排贡献。"))
                featureRow(icon: "brain.head.profile", color: DS.Category.hazardous,
                           title: language.text("AI Coach", "智能教练"),
                           body: language.text("Personalised tips based on your history.",
                                               "基于你的历史记录生成个性化建议。"))
            }
            .padding(.horizontal, DS.Spacing.md)

            pageIndicator(active: 1)

            Spacer()

            Button {
                settingsStore.hasSeenOnboarding = true
            } label: {
                Text(language.text("Get Started", "开始使用"))
                    .primaryButtonStyle()
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.bottom, DS.Spacing.xl)
        }
    }

    private func featureRow(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundColor(DS.textPrimary)
                Text(body).font(.caption).foregroundColor(DS.textSecondary)
            }
            Spacer()
        }
        .padding(DS.Spacing.md)
        .background(DS.surface)
        .cornerRadius(DS.Radius.control)
        .cardShadow()
    }

    private func pageIndicator(active: Int) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            ForEach(0..<2) { i in
                Capsule()
                    .fill(i == active ? DS.primary : DS.border)
                    .frame(width: i == active ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: active)
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(SettingsStore())
    }
}
