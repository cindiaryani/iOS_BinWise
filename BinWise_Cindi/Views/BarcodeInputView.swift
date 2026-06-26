import SwiftUI

/// Barcode scanning screen: live camera preview → Open Food Facts lookup → Advisor Agent → ResultView.
/// On Simulator (no camera), falls back to a manual barcode text-entry field.
struct BarcodeInputView: View {

    // MARK: – Dependencies

    @EnvironmentObject var settingsStore: SettingsStore
    @StateObject private var barcodeVM   = BarcodeScanViewModel()
    @StateObject private var scanVM      = ScanViewModel()
    @Environment(\.appLanguage) var language

    // MARK: – Navigation

    @State private var showResult = false

    // MARK: – Simulator fallback

    @State private var manualEntry = ""
    private var cameraAvailable: Bool { BarcodeScannerView.isCameraAvailable }

    // MARK: – Body

    var body: some View {
        ZStack(alignment: .bottom) {
            if cameraAvailable {
                cameraLayer
                viewfinderOverlay
            } else {
                simulatorLayer
            }

            phaseCard
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.bottom, 120)

            if scanVM.stage == .advising {
                advisingOverlay
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(language.text("Barcode Scan", "条形码扫描"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scanVM.stage) { stage in
            if stage == .complete { showResult = true }
        }
        .navigationDestination(isPresented: $showResult) {
            ResultView(viewModel: scanVM)
        }
        .onDisappear {
            if !showResult { scanVM.reset() }
        }
    }

    // MARK: – Camera layer

    private var cameraLayer: some View {
        BarcodeScannerView { code in
            barcodeVM.processBarcode(code)
        }
        .ignoresSafeArea()
    }

    // MARK: – Viewfinder overlay (Section D: centered inside the exact preview frame)

    @State private var scanLineOffset: CGFloat = 0

    private var viewfinderOverlay: some View {
        GeometryReader { geo in
            let w = geo.size.width * 0.72
            let h: CGFloat = 140
            let centerX = geo.size.width / 2
            let centerY = geo.size.height / 2

            ZStack {
                Color.black.opacity(0.45)
                    .mask(
                        Rectangle()
                            .fill(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: w, height: h)
                                    .position(x: centerX, y: centerY)
                                    .blendMode(.destinationOut)
                            )
                    )
                    .compositingGroup()

                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(DS.brandAmber, lineWidth: 2.5)
                    .frame(width: w, height: h)
                    .position(x: centerX, y: centerY)

                // Animated scanning line
                Rectangle()
                    .fill(DS.brandAmber)
                    .frame(width: w - 16, height: 2)
                    .shadow(color: DS.brandAmber.opacity(0.8), radius: 4)
                    .position(x: centerX, y: centerY - h / 2 + 8 + scanLineOffset)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                            scanLineOffset = h - 16
                        }
                    }

                VStack {
                    Spacer().frame(height: centerY + h / 2 + DS.Spacing.md)
                    Text(language.text("Align barcode within the frame",
                                       "将条形码对准框内"))
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.6), radius: 4)
                    Spacer()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: – Simulator fallback

    private var simulatorLayer: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            VStack(spacing: DS.Spacing.md) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(DS.border)
                Text(language.text("Camera not available on Simulator", "模拟器上无摄像头"))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(DS.textSecondary)
                Text(language.text("Enter a barcode manually to test the lookup:",
                                    "手动输入条形码进行测试："))
                    .font(.caption)
                    .foregroundColor(DS.textSecondary)
                HStack(spacing: DS.Spacing.sm) {
                    TextField("e.g. 5449000214911", text: $manualEntry)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    Button(language.text("Look up", "查找")) {
                        let code = manualEntry.trimmingCharacters(in: .whitespaces)
                        guard !code.isEmpty else { return }
                        barcodeVM.processBarcode(code)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(DS.primary)
                    .disabled(manualEntry.isEmpty)
                }
                .padding(.horizontal, DS.Spacing.lg)
            }
            .padding(.top, DS.Spacing.xl)
        }
    }

    // MARK: – Phase card

    @ViewBuilder
    private var phaseCard: some View {
        switch barcodeVM.phase {
        case .scanning:
            scanningCard
        case .fetching:
            fetchingCard
        case .ready:
            readyCard
        case .notFound(let msg):
            errorCard(message: msg, isRecoverable: true)
        case .error(let msg):
            errorCard(message: msg, isRecoverable: true)
        }
    }

    private var scanningCard: some View {
        HStack(spacing: DS.Spacing.sm) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
            Text(language.text("Scanning for barcode…", "正在扫描条形码…"))
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Spacing.md)
        .background(Color.black.opacity(0.65))
        .cornerRadius(DS.Radius.card)
    }

    private var fetchingCard: some View {
        VStack(spacing: DS.Spacing.sm) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(DS.primary)
            Text(language.text("Looking up product…", "正在查找产品…"))
                .font(.subheadline.weight(.medium))
                .foregroundColor(DS.textPrimary)
            Text(barcodeVM.detectedBarcode)
                .font(.caption.monospaced())
                .foregroundColor(DS.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Spacing.md)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    private var readyCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Label(language.text("Product found", "已找到产品"),
                      systemImage: "barcode.viewfinder")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(DS.primary)
                Text(barcodeVM.productName)
                    .font(.headline)
                    .foregroundColor(DS.textPrimary)
                if !barcodeVM.packagingSummary.isEmpty {
                    HStack(alignment: .top, spacing: DS.Spacing.xs) {
                        Image(systemName: "shippingbox")
                            .font(.caption)
                            .foregroundColor(DS.textSecondary)
                        Text(barcodeVM.packagingSummary)
                            .font(.caption)
                            .foregroundColor(DS.textSecondary)
                    }
                }
            }

            Divider()

            Button {
                scanVM.reset()
                scanVM.processWithAssessment(barcodeVM.makeAssessment(), image: nil)
            } label: {
                Label(language.text("Get Sorting Advice", "获取分类建议"),
                      systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.sm)
                    .background(DS.primary)
                    .cornerRadius(DS.Radius.control)
            }

            Button { barcodeVM.retry() } label: {
                Text(language.text("Scan another barcode", "扫描其他条形码"))
                    .font(.subheadline)
                    .foregroundColor(DS.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    private func errorCard(message: String, isRecoverable: Bool) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Label(language.text("Not found", "未找到"),
                  systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if isRecoverable {
                Button { barcodeVM.retry() } label: {
                    Text(language.text("Try again", "重试"))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.sm)
                        .background(DS.primary)
                        .cornerRadius(DS.Radius.control)
                }
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    // MARK: – Advising overlay

    private var advisingOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: DS.Spacing.md) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.4)
                Text(language.text("Asking Advisor Agent…", "正在咨询建议…"))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
            }
            .padding(DS.Spacing.xl)
            .background(Color.black.opacity(0.75))
            .cornerRadius(DS.Radius.card)
        }
    }
}

struct BarcodeInputView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BarcodeInputView()
                .environmentObject(SettingsStore())
        }
    }
}
