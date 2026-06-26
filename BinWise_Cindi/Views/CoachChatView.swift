import SwiftUI

/// Multi-turn conversational AI coach view.
/// Sends messages to CoachChatViewModel, renders chat bubbles,
/// and preserves history across sessions via UserDefaults.
struct CoachChatView: View {

    /// Optional pre-filled question — sent automatically on first appear.
    /// Used by the "Ask About…" quick-topic cards on the Learn screen.
    var initialQuestion: String? = nil

    // MARK: – Dependencies

    @EnvironmentObject var historyStore:  HistoryStore
    @EnvironmentObject var quizStore:     QuizStore

    @StateObject private var vm = CoachChatViewModel()
    @Environment(\.appLanguage) var language

    // MARK: – Local state

    @State private var showClearAlert = false
    @State private var didSendInitial = false

    // MARK: – Body

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            VStack(spacing: 0) {
                if let err = vm.errorMessage {
                    errorBanner(err)
                }
                messageArea
            }
        }
        .navigationTitle("Coach 🤖")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showClearAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(vm.messages.isEmpty ? DS.border : DS.textSecondary)
                }
                .disabled(vm.messages.isEmpty)
                .accessibilityLabel("Clear chat history")
            }
        }
        .alert(language.text("Clear conversation?", "清空对话？"),
               isPresented: $showClearAlert) {
            Button(language.text("Clear", "清空"), role: .destructive) { vm.clearChat() }
            Button(language.text("Cancel", "取消"), role: .cancel) {}
        } message: {
            Text(language.text("This cannot be undone.", "此操作不可撤销。"))
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                quickReplyChips
                inputBar
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 90)
        }
        .onAppear {
            vm.configure(historyStore: historyStore, quizStore: quizStore)
            if !didSendInitial, let question = initialQuestion, !question.isEmpty {
                didSendInitial = true
                vm.inputText = question
                Task { await vm.sendMessage() }
            }
        }
    }

    // MARK: – Message area

    private var messageArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: DS.Spacing.sm) {
                    if vm.messages.isEmpty {
                        welcomeCard
                            .padding(.top, DS.Spacing.xl)
                            .id("welcome")
                    } else {
                        ForEach(vm.messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    if vm.isLoading {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.md)
                .animation(.spring(response: 0.4), value: vm.messages.count)
                .animation(.easeInOut(duration: 0.2), value: vm.isLoading)
            }
            .onChange(of: vm.messages.count) { _ in
                withAnimation {
                    if let last = vm.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: vm.isLoading) { loading in
                if loading {
                    withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                }
            }
        }
    }

    // MARK: – Welcome card

    private var welcomeCard: some View {
        VStack(spacing: DS.Spacing.md) {
            Text("🤖")
                .font(.system(size: 64))
            Text(language.text("Ask me anything!", "问我任何问题！"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(DS.textPrimary)
            Text(language.text("Your waste sorting AI assistant", "垃圾分类小助手"))
                .font(.subheadline)
                .foregroundColor(DS.textSecondary)

            Divider().padding(.vertical, DS.Spacing.xs)

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                exampleButton(language.text(
                    "Is a used tissue recyclable?",
                    "用过的纸巾可以回收吗？"
                ))
                exampleButton(language.text(
                    "Where does a dead battery go?",
                    "废电池怎么分类？"
                ))
                exampleButton(language.text(
                    "Give me a tip about kitchen waste",
                    "厨余垃圾总出错，给建议"
                ))
            }
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
        .padding(.horizontal, DS.Spacing.xs)
    }

    private func exampleButton(_ text: String) -> some View {
        Button {
            vm.inputText = text
        } label: {
            HStack {
                Image(systemName: "bubble.left")
                    .font(.caption)
                    .foregroundColor(DS.primary)
                Text(text)
                    .font(.caption)
                    .foregroundColor(DS.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(DS.border)
            }
            .padding(DS.Spacing.sm)
            .background(DS.background)
            .cornerRadius(DS.Radius.control)
        }
        .accessibilityLabel("Use example: \(text)")
    }

    // MARK: – Quick-reply chips (Section G)

    private var quickReplyChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.sm) {
                quickReplyChip(language.text("What's tricky today? 🤔", "今天有什么易错题？🤔"))
                quickReplyChip(language.text("Quiz me! 🎯", "考考我！🎯"))
                quickReplyChip(language.text("Give me a tip 💡", "给我一个建议 💡"))
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.top, DS.Spacing.sm)
        }
    }

    private func quickReplyChip(_ text: String) -> some View {
        Button {
            vm.inputText = text
            Task { await vm.sendMessage() }
        } label: {
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundColor(DS.textPrimary)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(DS.brandAmberTint)
                .cornerRadius(DS.Radius.badge)
                .overlay(Capsule().stroke(DS.brandAmberLight, lineWidth: 1))
        }
        .disabled(vm.isLoading)
    }

    // MARK: – Input bar

    private var inputBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            TextField(language.text("Ask about any waste item…", "问我任何垃圾分类问题"),
                      text: $vm.inputText, axis: .vertical)
                .lineLimit(1...4)
                .font(.subheadline)
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.sm)
                .background(DS.surface)
                .cornerRadius(DS.Radius.control)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.control)
                        .stroke(DS.border, lineWidth: 1)
                )
                .onSubmit {
                    if !vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                        Task { await vm.sendMessage() }
                    }
                }

            Button {
                Task { await vm.sendMessage() }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        (vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading)
                            ? DS.border : DS.primary
                    )
                    .clipShape(Circle())
            }
            .disabled(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(DS.background.opacity(0.95))
    }

    // MARK: – Error banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(DS.textPrimary)
                .lineLimit(2)
            Spacer()
            Button { vm.errorMessage = nil } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(DS.textSecondary)
            }
        }
        .padding(DS.Spacing.sm)
        .background(Color.orange.opacity(0.12))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.orange.opacity(0.3)),
            alignment: .bottom
        )
    }
}

// MARK: – Message bubble

/// Single chat bubble. User bubbles are right-aligned teal; assistant bubbles are left-aligned
/// white with a teal left border — mimicking a speech-tail asymmetry.
struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(alignment: .bottom, spacing: DS.Spacing.sm) {
            if isUser { Spacer(minLength: 48) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.subheadline)
                    .foregroundColor(isUser ? .white : DS.textPrimary)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.sm)
                    .background(isUser ? DS.primary : DS.surface)
                    .clipShape(MessageBubbleShape(isUser: isUser))
                    .if(!isUser) { v in
                        v.overlay(
                            HStack {
                                Rectangle()
                                    .fill(DS.primary)
                                    .frame(width: 3)
                                Spacer()
                            }
                            .clipShape(MessageBubbleShape(isUser: false))
                        )
                    }
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

                Text(Self.timeFormatter.string(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(DS.textSecondary)
                    .padding(.horizontal, 4)
            }

            if !isUser { Spacer(minLength: 48) }
        }
        .accessibilityLabel("\(isUser ? "You" : "Coach"): \(message.content)")
    }
}

// MARK: – Bubble shape

/// Asymmetric rounded rect: all corners large except the "tail" corner (small).
private struct MessageBubbleShape: Shape {
    let isUser: Bool
    private let large: CGFloat = DS.Radius.card
    private let small: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        let tl: CGFloat = large
        let tr: CGFloat = large
        let bl: CGFloat = isUser ? large : small
        let br: CGFloat = isUser ? small : large
        return Path { p in
            p.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
            p.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
                     radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
            p.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
                     radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            p.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
            p.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
                     radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
            p.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
                     radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }
    }
}

// MARK: – Typing indicator

/// Animated 3-dot pulse shown while the assistant is generating a reply.
struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: DS.Spacing.sm) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(DS.primary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(phase == i ? 1.4 : 0.85)
                        .animation(
                            .easeInOut(duration: 0.45)
                                .repeatForever()
                                .delay(Double(i) * 0.15),
                            value: phase
                        )
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .background(DS.surface)
            .clipShape(MessageBubbleShape(isUser: false))
            .overlay(
                HStack {
                    Rectangle().fill(DS.primary).frame(width: 3)
                    Spacer()
                }
                .clipShape(MessageBubbleShape(isUser: false))
            )
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            Spacer(minLength: 48)
        }
        .onAppear {
            withAnimation { phase = 1 }
        }
        .accessibilityLabel("Coach is typing")
    }
}

// MARK: – View modifier helper

private extension View {
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: – Preview

struct CoachChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CoachChatView()
                .environmentObject(HistoryStore())
                .environmentObject(QuizStore())
        }
    }
}
