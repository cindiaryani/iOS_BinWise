import SwiftUI
import AVFoundation

/// Combines the live camera preview with the classification overlay and agent pipeline.
///
/// Handoff to ScanViewModel:
///   1. LiveScanViewModel fires `onAutoTrigger(result, image)` when stability locks.
///   2. This container calls `scanVM.processWithKnownResult(_:image:)` — skips Vision and
///      runs both Claude agents exactly like the photo flow.
///   3. When `scanVM.stage == .complete`, we push ResultView onto the NavigationStack.
struct LiveCameraContainerView: View {

    @StateObject private var liveVM           = LiveScanViewModel()
    @StateObject private var scanVM           = ScanViewModel()
    @StateObject private var classifierCheck  = ClassifierService()
    @State private var showResult             = false
    @State private var cameraPermissionDenied = false
    @Environment(\.appLanguage) var language

    private var cameraAvailable: Bool { LiveCameraPreviewView.isCameraAvailable }

    var body: some View {
        ZStack {
            if cameraAvailable && !cameraPermissionDenied {
                cameraContent
            } else if cameraPermissionDenied {
                permissionDeniedView
            } else {
                simulatorFallback
            }
        }
        .overlay(ModelStatusBanner(isModelLoaded: classifierCheck.isModelLoaded), alignment: .top)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear(perform: setupPipeline)
        .onChange(of: scanVM.stage) { stage in
            if stage == .complete { showResult = true }
        }
        .onChange(of: showResult) { showing in
            if !showing {
                scanVM.reset()
                liveVM.reset()
            }
        }
        .navigationDestination(isPresented: $showResult) {
            ResultView(viewModel: scanVM)
        }
        .onAppear(perform: checkPermission)
    }

    // MARK: – Setup

    private func setupPipeline() {
        liveVM.onAutoTrigger = { [weak scanVM] result, image in
            scanVM?.processWithKnownResult(result, image: image)
        }
        liveVM.activate()
    }

    private func checkPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraPermissionDenied = (status == .denied || status == .restricted)
    }

    // MARK: – Camera content

    private var cameraContent: some View {
        ZStack(alignment: .bottom) {
            LiveCameraPreviewView { [weak liveVM] label, conf, img in
                liveVM?.processFrame(label: label, confidence: conf, capturedImage: img)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBadge
                    .padding(.top, 60)
                    .padding(.horizontal, DS.Spacing.md)
                Spacer()
                bottomControls
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.bottom, DS.Spacing.xl)
            }
            .ignoresSafeArea(edges: .bottom)

            if isProcessing {
                processingOverlay
            }
        }
    }

    private var isProcessing: Bool {
        liveVM.scanState == .processing ||
        scanVM.stage == .interpreting ||
        scanVM.stage == .advising
    }

    // MARK: – Top badge

    private var topBadge: some View {
        VStack(spacing: DS.Spacing.xs) {
            categoryPill
            if !liveVM.currentLabel.isEmpty, !isSearching {
                Text("\(liveVM.currentLabel.replacingOccurrences(of: "_", with: " ").capitalized)  ·  \(Int(liveVM.currentConfidence * 100))%")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(radius: 2)
            }
            if case .locking(let p) = liveVM.scanState {
                lockingRing(progress: p)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: liveVM.scanState)
    }

    private var isSearching: Bool {
        switch liveVM.scanState {
        case .searching: return true
        default:         return liveVM.currentConfidence < 0.70
        }
    }

    private var categoryPill: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: isSearching ? "viewfinder" : liveVM.currentCategory.iconName)
                .font(.system(size: 14, weight: .semibold))
            Text(isSearching
                 ? language.text("Hold steady…", "保持稳定")
                 : language.text(liveVM.currentCategory.englishName,
                                 liveVM.currentCategory.chineseName))
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(
            (isSearching ? Color.gray : liveVM.currentCategory.color)
                .opacity(0.80)
        )
        .cornerRadius(DS.Radius.badge)
    }

    private func lockingRing(progress: Double) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 3)
                .frame(width: 36, height: 36)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(DS.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 36, height: 36)
                .animation(.linear(duration: 0.15), value: progress)
        }
    }

    // MARK: – Bottom controls

    private var bottomControls: some View {
        VStack(spacing: DS.Spacing.sm) {
            if liveVM.showFallbackButton, !isProcessing {
                fallbackButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if case .error(let msg) = scanVM.stage {
                errorRetryBanner(msg)
            }
        }
        .animation(.spring(response: 0.35), value: liveVM.showFallbackButton)
    }

    private var fallbackButton: some View {
        VStack(spacing: DS.Spacing.xs) {
            Button { liveVM.tapToScanNow() } label: {
                Label(language.text("Tap to scan now", "点击立即扫描"),
                      systemImage: "bolt.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.md)
                    .background(DS.primary.opacity(0.90))
                    .cornerRadius(DS.Radius.control)
            }
            Text(language.text(
                "Trouble locking on? Tap to scan the current view.",
                "无法自动锁定？点击立即扫描当前画面。"
            ))
            .font(.caption)
            .foregroundColor(.white.opacity(0.70))
            .multilineTextAlignment(.center)
        }
    }

    private func errorRetryBanner(_ message: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button(language.text("Retry", "重试")) {
                scanVM.reset()
                liveVM.reset()
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(.white)
        }
        .padding(DS.Spacing.sm)
        .background(Color.red.opacity(0.80))
        .cornerRadius(DS.Radius.control)
    }

    // MARK: – Processing overlay

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.60)
                .ignoresSafeArea()

            VStack(spacing: DS.Spacing.lg) {
                if let img = scanVM.capturedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                        .cardShadow()
                }
                AgentPipelineView(stage: scanVM.stage)
                    .padding(.horizontal, DS.Spacing.lg)
            }
            .padding(DS.Spacing.lg)
        }
        .transition(.opacity)
        .animation(.easeIn(duration: 0.25), value: isProcessing)
    }

    // MARK: – Permission denied

    private var permissionDeniedView: some View {
        VStack(spacing: DS.Spacing.lg) {
            Image(systemName: "camera.fill")
                .font(.system(size: 56))
                .foregroundColor(DS.border)
            Text(language.text("Camera Access Required", "需要相机权限"))
                .font(.title3.weight(.semibold))
                .foregroundColor(DS.textPrimary)
            Text(language.text(
                "BinWise needs camera access for live classification.",
                "BinWise需要相机权限才能进行实时识别。"
            ))
            .multilineTextAlignment(.center)
            .font(.subheadline)
            .foregroundColor(DS.textSecondary)
            Button {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            } label: {
                Text(language.text("Open Settings", "打开设置"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.md)
                    .background(DS.primary)
                    .cornerRadius(DS.Radius.control)
            }
        }
        .padding(DS.Spacing.xl)
    }

    // MARK: – Simulator fallback

    private var simulatorFallback: some View {
        VStack(spacing: DS.Spacing.lg) {
            Image(systemName: "camera.fill")
                .font(.system(size: 56))
                .foregroundColor(DS.border)
            Text(language.text("Live camera not available", "实时摄像头不可用"))
                .font(.title3.weight(.semibold))
                .foregroundColor(DS.textPrimary)
            Text(language.text(
                "Running on Simulator — tap \"Use a photo\" on the home screen to test the full pipeline.",
                "模拟器运行中 — 请在首页点击「使用照片」测试完整流程。"
            ))
            .multilineTextAlignment(.center)
            .font(.subheadline)
            .foregroundColor(DS.textSecondary)
        }
        .padding(DS.Spacing.xl)
    }
}
