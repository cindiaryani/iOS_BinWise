import SwiftUI
import AVFoundation

// MARK: – Detection delegate

protocol BarcodeDetectionDelegate: AnyObject {
    func didDetectBarcode(_ string: String)
}

// MARK: – View controller

/// AVFoundation view controller that detects 1-D and 2-D barcodes.
/// Stops the session immediately after the first detection so the result
/// is delivered exactly once.
final class BarcodeScannerViewController: UIViewController {

    weak var delegate: BarcodeDetectionDelegate?

    private let captureSession   = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue     = DispatchQueue(label: "binwise.barcode.session")
    private var hasDetected      = false

    // MARK: – Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupPreview()
        requestPermissionAndStart()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async { [weak self] in
            guard let self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }

    // MARK: – Public

    /// Re-enables scanning (e.g. after a failed API lookup).
    func resumeScanning() {
        hasDetected = false
        sessionQueue.async { [weak self] in
            guard let self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }

    // MARK: – Private

    private func setupPreview() {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        previewLayer = layer
    }

    private func requestPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            sessionQueue.async { self.configure() }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                self?.sessionQueue.async { self?.configure() }
            }
        default:
            break
        }
    }

    private func configure() {
        captureSession.beginConfiguration()

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video, position: .back),
            let input  = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(input)
        else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(output) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addOutput(output)
        // Delegate must be set after addOutput so metadataObjectTypes can be configured.
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.ean13, .ean8, .upce, .code128, .qr]

        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
}

// MARK: – AVCaptureMetadataOutputObjectsDelegate

extension BarcodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard
            !hasDetected,
            let obj  = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let code = obj.stringValue, !code.isEmpty
        else { return }
        hasDetected = true
        // Stop session on the session queue to avoid blocking the main thread.
        sessionQueue.async { [weak self] in self?.captureSession.stopRunning() }
        delegate?.didDetectBarcode(code)
    }
}

// MARK: – SwiftUI representable

/// Wraps `BarcodeScannerViewController` for use in SwiftUI.
/// `isCameraAvailable` lets the host view fall back to manual entry on Simulator.
struct BarcodeScannerView: UIViewControllerRepresentable {

    let onDetected: (String) -> Void

    static var isCameraAvailable: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
    }

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let vc = BarcodeScannerViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController,
                                context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDetected: onDetected) }

    final class Coordinator: NSObject, BarcodeDetectionDelegate {
        let onDetected: (String) -> Void
        init(onDetected: @escaping (String) -> Void) { self.onDetected = onDetected }
        func didDetectBarcode(_ string: String) { onDetected(string) }
    }
}
