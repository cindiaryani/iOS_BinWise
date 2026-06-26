import SwiftUI

/// One-line amber banner shown when the Core ML model is not loaded.
/// Dismissed by tapping ✕. Hidden entirely when model is available.
struct ModelStatusBanner: View {
    @Environment(\.appLanguage) var language
    @State private var dismissed = false

    let isModelLoaded: Bool

    var body: some View {
        if !isModelLoaded && !dismissed {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text(language.text(
                    "Classifier model not found — camera preview only",
                    "分类模型未加载 — 仅相机预览模式"
                ))
                .font(.caption.weight(.medium))
                .foregroundColor(DS.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button {
                    withAnimation { dismissed = true }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(DS.textSecondary)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .background(Color.orange.opacity(0.15))
            .overlay(
                Rectangle()
                    .fill(Color.orange.opacity(0.4))
                    .frame(height: 1),
                alignment: .bottom
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
