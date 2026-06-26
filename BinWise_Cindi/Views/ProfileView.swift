import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM:        AuthViewModel
    @EnvironmentObject var historyStore:  HistoryStore
    @EnvironmentObject var quizStore:     QuizStore
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.appLanguage) var language

    @State private var showSignOutConfirm = false

    private var totalCO2: Double { historyStore.totalCO2() }
    private var streak: Int { GamificationService.streak(from: historyStore.records) }
    private var badges: [Badge] { GamificationService.badges(from: historyStore.records, quizStats: quizStore.stats) }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: DS.Spacing.lg) {
                        avatarHeader
                        statsGrid
                        badgesSection
                        settingsLinks
                        if !authVM.isGuest {
                            signOutButton
                        }
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.bottom, 90)
                }
            }
            .navigationTitle(language.text("Profile", "我的"))
            .navigationBarTitleDisplayMode(.large)
        }
        .confirmationDialog(
            language.text("Sign out?", "确认退出？"),
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button(language.text("Sign Out", "退出登录"), role: .destructive) {
                authVM.signOut()
            }
            Button(language.text("Cancel", "取消"), role: .cancel) {}
        }
    }

    // MARK: – Avatar header

    private var avatarHeader: some View {
        VStack(spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DS.tealGradient)
                    .frame(width: 88, height: 88)
                Text(avatarInitials)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(spacing: DS.Spacing.xs) {
                Text(displayName)
                    .font(.title2.weight(.bold))
                    .foregroundColor(DS.textPrimary)
                if let email = authVM.user?.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(DS.textSecondary)
                } else if authVM.isGuest {
                    Text(language.text("Guest user — sign in to save progress", "访客模式 — 登录以保存进度"))
                        .font(.caption)
                        .foregroundColor(DS.textSecondary)
                        .multilineTextAlignment(.center)
                }
                if let joinDate = authVM.user?.joinDate {
                    Text(language.text("Joined", "加入") + " " + joinDate.formatted(.dateTime.month().year()))
                        .font(.caption2)
                        .foregroundColor(DS.border)
                }
            }
        }
        .padding(.top, DS.Spacing.md)
    }

    private var displayName: String {
        if let profile = authVM.user { return profile.firstNameOrEmail }
        return authVM.isGuest ? language.text("Guest", "访客") : "BinWise"
    }

    private var avatarInitials: String {
        if let profile = authVM.user { return profile.initials }
        return authVM.isGuest ? "G" : "B"
    }

    // MARK: – Stats grid

    private var statsGrid: some View {
        VStack(spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.sm) {
                profileStat(value: "\(historyStore.records.count)",
                            label: language.text("Items Sorted", "已分类"),
                            icon: "checkmark.circle.fill", color: DS.success)
                profileStat(value: "\(streak)",
                            label: language.text("Day Streak", "连续天数"),
                            icon: "flame.fill", color: .orange)
            }
            HStack(spacing: DS.Spacing.sm) {
                profileStat(value: String(format: "%.2f kg", totalCO2),
                            label: language.text("CO₂ Saved", "碳减排"),
                            icon: "leaf.fill", color: DS.primary)
                profileStat(value: "\(badges.filter(\.unlocked).count)/\(badges.count)",
                            label: language.text("Badges", "成就"),
                            icon: "star.fill", color: .yellow)
            }
        }
    }

    private func profileStat(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(DS.textPrimary)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(DS.textSecondary)
            }
            Spacer()
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: – Badges

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            DS.sectionHeader(language.text("Achievements", "成就"))
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: DS.Spacing.sm) {
                ForEach(badges) { badge in
                    badgeCell(badge)
                }
            }
            .padding(DS.Spacing.md)
            .cardStyle()
        }
    }

    private func badgeCell(_ badge: Badge) -> some View {
        VStack(spacing: DS.Spacing.xs) {
            Image(systemName: badge.icon)
                .font(.title)
                .foregroundColor(badge.unlocked ? DS.primary : DS.border)
            Text(badge.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(badge.unlocked ? DS.textPrimary : DS.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(DS.Spacing.sm)
        .frame(maxWidth: .infinity)
        .opacity(badge.unlocked ? 1 : 0.45)
    }

    // MARK: – Settings links

    private var settingsLinks: some View {
        VStack(spacing: 0) {
            DS.sectionHeader(language.text("Settings", "设置"))
                .padding(.bottom, DS.Spacing.xs)

            VStack(spacing: 0) {
                NavigationLink { SettingsView() } label: {
                    settingsRow(icon: "gearshape.fill", title: language.text("App Settings", "应用设置"), color: DS.textSecondary)
                }
                Divider().padding(.leading, 52)
                NavigationLink { HistoryView() } label: {
                    settingsRow(icon: "clock.arrow.circlepath", title: language.text("Sort History", "分类历史"), color: DS.textSecondary)
                }
                Divider().padding(.leading, 52)
                NavigationLink { ImpactView() } label: {
                    settingsRow(icon: "chart.bar.fill", title: language.text("Impact Dashboard", "贡献统计"), color: DS.textSecondary)
                }
                Divider().padding(.leading, 52)
                NavigationLink { StatisticsView() } label: {
                    settingsRow(icon: "chart.line.uptrend.xyaxis", title: language.text("Statistics", "数据统计"), color: DS.textSecondary)
                }
            }
            .cardStyle()
        }
    }

    private func settingsRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 28)
            Text(title)
                .font(.body)
                .foregroundColor(DS.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(DS.border)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm + DS.Spacing.xs)
    }

    // MARK: – Sign out

    private var signOutButton: some View {
        Button {
            showSignOutConfirm = true
        } label: {
            Label(language.text("Sign Out", "退出登录"), systemImage: "rectangle.portrait.and.arrow.right")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.md)
                .background(Color.red.opacity(0.08))
                .cornerRadius(DS.Radius.control)
        }
    }
}
