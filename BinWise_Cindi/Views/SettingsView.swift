import SwiftUI

/// User-configurable settings: language, voice, confidence threshold, and data reset.
struct SettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var historyStore: HistoryStore
    @EnvironmentObject var quizStore: QuizStore
    @State private var showResetAlert = false

    private var language: AppLanguage { settingsStore.language }

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            List {
                displaySection
                voiceSection
                classificationSection
                dangerSection
            }
            .listStyle(.insetGrouped)
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 90) }
        }
        .navigationTitle(language.text("Settings", "设置"))
        .navigationBarTitleDisplayMode(.large)
        .alert(language.text("Reset All Data?", "确认清空数据？"),
               isPresented: $showResetAlert) {
            Button(language.text("Reset", "确认清空"), role: .destructive) {
                historyStore.resetAll()
                quizStore.reset()
            }
            Button(language.text("Cancel", "取消"), role: .cancel) {}
        } message: {
            Text(language.text(
                "This permanently deletes all sort history, quiz stats, and CO₂ data.",
                "所有记录将永久删除，无法恢复。"
            ))
        }
    }

    // MARK: – Display

    private var displaySection: some View {
        Section {
            Picker(language.text("Language", "语言"), selection: $settingsStore.language) {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Text(lang.rawValue).tag(lang)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text(language.text("Display", "显示"))
        } footer: {
            Text(language.text(
                "Affects category labels and the voice used for read-aloud guidance.",
                "影响分类标签和语音朗读所使用的语言。"
            ))
        }
    }

    // MARK: – Voice

    private var voiceSection: some View {
        Section {
            Toggle(isOn: $settingsStore.voiceEnabled) {
                Label(language.text("Voice Feedback", "语音反馈"),
                      systemImage: "speaker.wave.2.fill")
            }
            .tint(DS.primary)
        } header: {
            Text(language.text("Voice", "语音"))
        } footer: {
            Text(language.text(
                "When on, the Advisor Agent's guidance is read aloud on the Result screen.",
                "开启后，系统将在结果页面朗读建议内容。"
            ))
        }
    }

    // MARK: – Classification

    private var classificationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                HStack {
                    Text(language.text("Confidence threshold", "置信度阈值"))
                        .font(.subheadline)
                        .foregroundColor(DS.textPrimary)
                    Spacer()
                    Text("\(Int(settingsStore.confidenceThreshold * 100))%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(DS.primary)
                }
                Slider(value: $settingsStore.confidenceThreshold,
                       in: 0.50...0.95, step: 0.05)
                    .accentColor(DS.primary)
            }
            .padding(.vertical, DS.Spacing.xs)
        } header: {
            Text(language.text("Classification", "识别"))
        } footer: {
            Text(language.text(
                "Minimum confidence for live-camera auto-lock. Lower = triggers faster; higher = more accurate.",
                "实时摄像头自动锁定的最低置信度。越低触发越快，越高越准确。"
            ))
        }
    }

    // MARK: – Danger zone

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Label(language.text("Reset All Data", "清空所有数据"),
                      systemImage: "trash.fill")
            }
        } header: {
            Text(language.text("Data", "数据"))
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(SettingsStore())
                .environmentObject(HistoryStore())
                .environmentObject(QuizStore())
        }
    }
}
