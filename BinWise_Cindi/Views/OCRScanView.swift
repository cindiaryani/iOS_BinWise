import SwiftUI
import AVFoundation
import Vision

/// OCR scanning screen: photo / gallery / live camera → Vision text recognition
/// → material keyword → Advisor Agent → ResultView.
struct OCRScanView: View {

    // MARK: – Dependencies

    @EnvironmentObject var settingsStore: SettingsStore
    @StateObject private var ocrVM  = OCRScanViewModel()
    @StateObject private var scanVM = ScanViewModel()
    @Environment(\.appLanguage) var language

    // MARK: – Image picker state

    @State private var showSourceDialog = false
    @State private var showPicker       = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var pickedImage: UIImage?

    // MARK: – Live camera

    @State private var showLiveCamera = false

    // MARK: – Navigation

    @State private var showResult = false

    // MARK: – Body

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    headerCard
                    imageSection
                    phaseContent
                    Spacer(minLength: DS.Spacing.xl)
                }
                .padding(DS.Spacing.lg)
                .padding(.bottom, 90)
            }

            if scanVM.stage == .advising {
                advisingOverlay
            }
        }
        .navigationTitle(language.text("Scan Label (OCR)", "扫描标签（OCR）"))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(language.text("Choose Image Source", "选择图片来源"),
                            isPresented: $showSourceDialog,
                            titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(language.text("Take Photo", "拍照")) {
                    sourceType = .camera; showPicker = true
                }
            }
            Button(language.text("Choose from Library", "从相册选择")) {
                sourceType = .photoLibrary; showPicker = true
            }
            Button(language.text("Cancel", "取消"), role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showPicker, onDismiss: {
            guard let img = pickedImage else { return }
            pickedImage = nil
            ocrVM.processImage(img)
        }) {
            CameraPicker(image: $pickedImage, sourceType: sourceType)
        }
        .fullScreenCover(isPresented: $showLiveCamera) {
            OCRLiveView(language: language) { material, image in
                ocrVM.setDetectedMaterial(material, image: image)
            }
        }
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

    // MARK: – Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label(language.text("How to use", "使用方法"), systemImage: "info.circle")
                .font(.caption.weight(.semibold))
                .foregroundColor(DS.textSecondary)
            Text(language.text(
                "Photograph the recycling symbol or material label on your packaging. BinWise will identify the plastic type and give you disposal guidance.",
                "拍摄包装上的回收标志或材质说明，AI将识别塑料类型并给出分类建议。"
            ))
            .font(.caption)
            .foregroundColor(DS.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    // MARK: – Image section

    private var imageSection: some View {
        VStack(spacing: DS.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(DS.surface)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .cardShadow()

                if let img = ocrVM.capturedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 220)
                        .clipped()
                        .cornerRadius(DS.Radius.card)
                } else {
                    VStack(spacing: DS.Spacing.sm) {
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 56))
                            .foregroundColor(DS.border)
                        Text(language.text("No image selected yet", "尚未选择图片"))
                            .font(.caption)
                            .foregroundColor(DS.textSecondary)
                    }
                }
            }

            // Action buttons row
            HStack(spacing: DS.Spacing.sm) {
                // Live camera scan
                Button {
                    ocrVM.reset()
                    scanVM.reset()
                    showResult = false
                    showLiveCamera = true
                } label: {
                    HStack(spacing: DS.Spacing.xs) {
                        Image(systemName: "camera.viewfinder")
                            .font(.subheadline.weight(.semibold))
                        Text(language.text("Live Scan", "实时扫描"))
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.sm)
                    .background(DS.brandCharcoal)
                    .cornerRadius(DS.Radius.control)
                }

                // Photo / gallery picker
                Button {
                    ocrVM.reset()
                    scanVM.reset()
                    showResult = false
                    showSourceDialog = true
                } label: {
                    HStack(spacing: DS.Spacing.xs) {
                        Image(systemName: ocrVM.phase == .idle ? "photo.on.rectangle" : "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
                        Text(ocrVM.phase == .idle
                             ? language.text("Photo", "从相册")
                             : language.text("Retry", "重新选择"))
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(DS.brandCharcoal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.sm)
                    .background(DS.surface)
                    .cornerRadius(DS.Radius.control)
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.control)
                        .stroke(DS.borderLight, lineWidth: 1))
                }
            }
        }
    }

    // MARK: – Phase content

    @ViewBuilder
    private var phaseContent: some View {
        switch ocrVM.phase {
        case .idle:
            EmptyView()
        case .recognizing:
            recognizingCard
        case .detected(let material):
            detectedCard(material: material)
        case .noMaterial:
            noMaterialCard
        case .error(let msg):
            errorCard(message: msg)
        }
    }

    private var recognizingCard: some View {
        HStack(spacing: DS.Spacing.sm) {
            ProgressView().progressViewStyle(.circular).tint(DS.primary)
            Text(language.text("Reading label…", "正在识别标签文字…"))
                .font(.subheadline.weight(.medium))
                .foregroundColor(DS.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Spacing.md)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    private func detectedCard(material: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Label(language.text("Material detected", "已识别材质"),
                  systemImage: "checkmark.seal.fill")
                .font(.caption.weight(.semibold))
                .foregroundColor(DS.success)

            Text(material)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(DS.textPrimary)

            Text(language.text(
                "The Advisor Agent will explain how to sort this material under China's waste classification system.",
                "AI将根据中国垃圾分类标准解释如何处理此材质。"
            ))
            .font(.caption)
            .foregroundColor(DS.textSecondary)
            .fixedSize(horizontal: false, vertical: true)

            Button {
                scanVM.reset()
                scanVM.processWithAssessment(ocrVM.makeAssessment(), image: ocrVM.capturedImage)
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
        }
        .padding(DS.Spacing.md)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    private var noMaterialCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label(language.text("No material detected", "未检测到材质标识"),
                  systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.orange)
            Text(language.text(
                "Make sure the recycling symbol (♻) or a material keyword such as PET, HDPE, PP, or \"plastic\" is visible and well-lit. Try the Live Scan mode for real-time detection.",
                "请确保图片中可以清晰看到回收符号（♻）或材质标注，如PET、HDPE、PP等。也可尝试实时扫描模式。"
            ))
            .font(.caption)
            .foregroundColor(DS.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    private func errorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label(language.text("Error", "错误"), systemImage: "xmark.octagon.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.red)
            Text(message)
                .font(.caption)
                .foregroundColor(DS.textSecondary)
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

// MARK: – Live OCR fullscreen view

/// Full-screen live camera that runs Vision OCR on each frame every ~1.5 s.
/// When a resin code / material keyword is detected it shows a result card.
struct OCRLiveView: View {
    let language: AppLanguage
    var onDetected: (String, UIImage?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var detectedMaterial: String? = nil
    @State private var capturedFrame: UIImage?    = nil

    var body: some View {
        ZStack {
            if LiveOCRPreviewView.isCameraAvailable {
                LiveOCRPreviewView { material, image in
                    guard detectedMaterial == nil else { return }
                    detectedMaterial = material
                    capturedFrame    = image
                }
                .ignoresSafeArea()

                viewfinderOverlay

                VStack {
                    Spacer()
                    statusCard
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.bottom, 48)
                }
            } else {
                DS.background.ignoresSafeArea()
                VStack(spacing: DS.Spacing.md) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 56))
                        .foregroundColor(DS.border)
                    Text(language.text("Camera not available", "摄像头不可用"))
                        .font(.headline)
                        .foregroundColor(DS.textPrimary)
                    Text(language.text("Use the Photo option instead.", "请使用相册选择图片。"))
                        .font(.subheadline)
                        .foregroundColor(DS.textSecondary)
                }
                .padding(DS.Spacing.xl)
            }
        }
        .overlay(alignment: .topLeading) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }
            .padding(.top, 56)
            .padding(.leading, DS.Spacing.md)
        }
    }

    // MARK: – Viewfinder overlay

    private var viewfinderOverlay: some View {
        GeometryReader { geo in
            let w        = geo.size.width * 0.88
            let h: CGFloat = 110
            let cx       = geo.size.width  / 2
            let cy       = geo.size.height * 0.40

            ZStack {
                // Dimmed mask with clear window
                Color.black.opacity(0.45)
                    .mask(
                        Rectangle().fill(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: w, height: h)
                                    .position(x: cx, y: cy)
                                    .blendMode(.destinationOut)
                            )
                    )
                    .compositingGroup()

                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(DS.brandAmber, lineWidth: 2.5)
                    .frame(width: w, height: h)
                    .position(x: cx, y: cy)

                VStack {
                    Spacer().frame(height: cy + h / 2 + DS.Spacing.md)
                    Text(language.text(
                        "Point at recycling symbols or material labels",
                        "对准回收符号或材质标注"
                    ))
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.6), radius: 4)
                    Spacer()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    // MARK: – Bottom status card

    @ViewBuilder
    private var statusCard: some View {
        if let material = detectedMaterial {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Label(language.text("Material detected!", "已检测到材质！"),
                      systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(DS.statusSuccess)

                Text(material)
                    .font(.title3.weight(.bold))
                    .foregroundColor(DS.textPrimary)

                Button {
                    onDetected(material, capturedFrame)
                    dismiss()
                } label: {
                    Text(language.text("Use This Result", "使用此结果"))
                        .primaryButtonStyle()
                }

                Button {
                    detectedMaterial = nil
                    capturedFrame    = nil
                } label: {
                    Text(language.text("Scan again", "重新扫描"))
                        .font(.subheadline)
                        .foregroundColor(DS.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(DS.Spacing.md)
            .background(DS.bgCard)
            .cornerRadius(DS.Radius.card)
            .cardShadow()
        } else {
            HStack(spacing: DS.Spacing.sm) {
                ProgressView().progressViewStyle(.circular).tint(.white)
                Text(language.text("Scanning for material labels…", "正在扫描材质标注…"))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(DS.Spacing.md)
            .background(Color.black.opacity(0.65))
            .cornerRadius(DS.Radius.card)
        }
    }
}

// MARK: – Live camera UIViewRepresentable (AVFoundation + Vision OCR)

struct LiveOCRPreviewView: UIViewRepresentable {

    static var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var onMaterialDetected: (String, UIImage?) -> Void

    func makeUIView(context: Context) -> _Preview {
        let v = _Preview()
        context.coordinator.setup(view: v)
        return v
    }

    func updateUIView(_ uiView: _Preview, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    // Thin UIView subclass that exposes the preview layer
    class _Preview: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: LiveOCRPreviewView
        private let session  = AVCaptureSession()
        private let queue    = DispatchQueue(label: "live.ocr.queue", qos: .userInitiated)
        private var lastScan = Date.distantPast
        private let interval: TimeInterval = 1.5
        private var busy     = false

        init(parent: LiveOCRPreviewView) { self.parent = parent }

        func setup(view: _Preview) {
            session.sessionPreset = .hd1280x720
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input  = try? AVCaptureDeviceInput(device: device),
                session.canAddInput(input)
            else { return }
            session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: queue)
            if session.canAddOutput(output) { session.addOutput(output) }

            view.previewLayer.session      = session
            view.previewLayer.videoGravity = .resizeAspectFill

            DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
        }

        func captureOutput(_ output: AVCaptureOutput,
                           didOutput sampleBuffer: CMSampleBuffer,
                           from connection: AVCaptureConnection) {
            let now = Date()
            guard now.timeIntervalSince(lastScan) >= interval, !busy else { return }
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            busy     = true
            lastScan = now

            let ci  = CIImage(cvPixelBuffer: pixelBuffer)
            let ctx = CIContext()
            guard let cg = ctx.createCGImage(ci, from: ci.extent) else { busy = false; return }
            let frame = UIImage(cgImage: cg)

            let req = VNRecognizeTextRequest { [weak self] r, _ in
                guard let self else { return }
                let lines = (r.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    ?? []
                if let material = ResinCodeService.parse(lines) {
                    DispatchQueue.main.async {
                        self.parent.onMaterialDetected(material, frame)
                    }
                }
                self.busy = false
            }
            req.recognitionLevel       = .fast
            req.recognitionLanguages   = ["en-US", "zh-Hans"]
            try? VNImageRequestHandler(cgImage: cg, options: [:]).perform([req])
        }
    }
}

struct OCRScanView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OCRScanView()
                .environmentObject(SettingsStore())
        }
    }
}
