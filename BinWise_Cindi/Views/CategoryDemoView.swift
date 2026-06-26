import SwiftUI

/// Animated step-through demo of how to prepare waste for each of the 4 China bins.
/// Pure SwiftUI animation — no images, no GIFs, no network.
struct CategoryDemoView: View {

    /// Pre-selected category (nil → starts on Recyclable).
    var initialCategory: WasteCategory?
    @Environment(\.appLanguage) var language

    @State private var selectedCategory: WasteCategory = .recyclable
    @State private var currentStep: Int = 0
    @State private var isAnimating: Bool = false

    private var guide: CategoryGuide { CategoryGuide.guide(for: selectedCategory) }

    private let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    categoryPicker
                    demoCard
                    examplesList
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.bottom, DS.Spacing.xl)
            }
        }
        .navigationTitle(language.text("How to Sort", "如何分类"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let cat = initialCategory { selectedCategory = cat }
            startAnimation()
        }
        .onDisappear { isAnimating = false }
        .onReceive(timer) { _ in
            guard isAnimating else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                currentStep = (currentStep + 1) % guide.steps.count
            }
        }
        .onChange(of: selectedCategory) { _ in
            currentStep = 0
            startAnimation()
        }
    }

    private func startAnimation() {
        isAnimating = true
    }

    // MARK: – Category picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.sm) {
                ForEach(CategoryGuide.all) { guide in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedCategory = guide.id
                        }
                    } label: {
                        HStack(spacing: DS.Spacing.xs) {
                            Image(systemName: guide.id.iconName)
                                .font(.caption.weight(.semibold))
                            Text(language.text(guide.titleEN, guide.titleCN))
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(selectedCategory == guide.id ? .white : guide.binColor)
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, DS.Spacing.sm)
                        .background(selectedCategory == guide.id ? guide.binColor : DS.surface)
                        .cornerRadius(DS.Radius.badge)
                        .overlay(
                            Capsule().stroke(guide.binColor.opacity(0.4), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.md)
        }
    }

    // MARK: – Animated step card

    private var demoCard: some View {
        VStack(spacing: DS.Spacing.lg) {
            // Header
            VStack(spacing: DS.Spacing.xs) {
                Text(language.text(guide.titleEN, guide.titleCN))
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                Text(language.text(guide.subtitleEN, guide.subtitleCN))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }

            // Animated step display
            VStack(spacing: DS.Spacing.md) {
                // Step icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 100, height: 100)
                    Image(systemName: guide.steps[currentStep].iconName)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(.white)
                        .id(currentStep) // forces re-render for transition
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.6).combined(with: .opacity),
                            removal: .scale(scale: 1.4).combined(with: .opacity)
                        ))
                }

                // Step label
                VStack(spacing: DS.Spacing.xs) {
                    Text("Step \(currentStep + 1) of \(guide.steps.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.70))
                    Text(language.text(guide.steps[currentStep].titleEN,
                                       guide.steps[currentStep].titleCN))
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .id("label-\(currentStep)")
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Progress dots
                HStack(spacing: DS.Spacing.sm) {
                    ForEach(guide.steps.indices, id: \.self) { idx in
                        Circle()
                            .fill(idx == currentStep ? Color.white : Color.white.opacity(0.35))
                            .frame(width: idx == currentStep ? 10 : 7,
                                   height: idx == currentStep ? 10 : 7)
                            .animation(.spring(response: 0.3), value: currentStep)
                    }
                }
            }

            // Manual step buttons
            HStack(spacing: DS.Spacing.md) {
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep = (currentStep - 1 + guide.steps.count) % guide.steps.count
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(DS.Spacing.sm)
                        .background(Color.white.opacity(0.20))
                        .clipShape(Circle())
                }

                Button {
                    isAnimating.toggle()
                } label: {
                    Image(systemName: isAnimating ? "pause.fill" : "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(DS.Spacing.sm)
                        .background(Color.white.opacity(0.20))
                        .clipShape(Circle())
                }

                Button {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep = (currentStep + 1) % guide.steps.count
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(DS.Spacing.sm)
                        .background(Color.white.opacity(0.20))
                        .clipShape(Circle())
                }
            }
        }
        .padding(DS.Spacing.lg)
        .background(guide.binColor)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    // MARK: – Examples list

    private var examplesList: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            DS.sectionHeader(language.text("Example Items", "典型示例"))

            VStack(spacing: 0) {
                ForEach(Array(guide.examples.enumerated()), id: \.offset) { idx, example in
                    HStack(spacing: DS.Spacing.md) {
                        Image(systemName: guide.id.iconName)
                            .font(.subheadline)
                            .foregroundColor(guide.binColor)
                            .frame(width: 28)
                        Text(example)
                            .font(.subheadline)
                            .foregroundColor(DS.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.sm)

                    if idx < guide.examples.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .cardStyle()
        }
    }
}

struct CategoryDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CategoryDemoView()
        }
    }
}
