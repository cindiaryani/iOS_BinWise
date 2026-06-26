import SwiftUI

/// Displays the captured image alongside the live AgentPipelineView while processing.
/// Navigates to ResultView on .complete via both onChange and onAppear (safety net).
struct ScanView: View {
    @ObservedObject var viewModel: ScanViewModel
    @State private var navigateToResult = false
    @Environment(\.appLanguage) var language

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    imageCard
                    AgentPipelineView(stage: viewModel.stage)
                        .padding(.horizontal, DS.Spacing.md)
                    if case .error(let msg) = viewModel.stage {
                        errorBanner(msg)
                    }
                }
                .padding(.top, DS.Spacing.lg)
            }
        }
        .navigationTitle(language.text("Analyzing…", "分析中"))
        .navigationBarTitleDisplayMode(.inline)
        // Primary trigger: stage changes to .complete while view is live
        .onChange(of: viewModel.stage) { newStage in
            if newStage == .complete {
                navigateToResult = true
            }
        }
        // Safety net: pipeline already finished before this view mounted
        .onAppear {
            if viewModel.stage == .complete {
                navigateToResult = true
            }
        }
        .navigationDestination(isPresented: $navigateToResult) {
            ResultView(viewModel: viewModel)
        }
    }

    // MARK: – Subviews

    private var imageCard: some View {
        Group {
            if let img = viewModel.capturedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .clipped()
                    .cornerRadius(DS.Radius.card)
                    .padding(.horizontal, DS.Spacing.md)
                    .cardShadow()
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.85))
        .cornerRadius(DS.Radius.control)
        .padding(.horizontal, DS.Spacing.md)
    }
}
