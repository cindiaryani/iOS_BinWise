import SwiftUI
import AVFoundation
import CoreImage
import UIKit

// MARK: – Frame delegate

/// Receives classified frame results from the capture pipeline.
protocol LiveFrameDelegate: AnyObject {
    func didClassify(label: String, confidence: Float, capturedImage: UIImage?)
}

// MARK: – UIViewController

/// Manages AVCaptureSession, AVCaptureVideoPreviewLayer, and per-frame Core ML classification.
final class LiveCameraViewController: UIViewController {

    weak var frameDelegate: LiveFrameDelegate?

    // MARK: – AV objects
    private let session          = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue     = DispatchQueue(label: "binwise.session",    qos: .userInitiated)
    private let classifyQueue    = DispatchQueue(label: "binwise.classify",   qos: .userInitiated)
    private let classifier       = LiveClassifierService()
    private let ciContext        = CIContext(options: [.useSoftwareRenderer: false])

    // Throttle to ~5 fps
    private var lastClassifyTime: CFTimeInterval = 0
    private let classifyInterval: CFTimeInterval = 0.2

    // MARK: – Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupPreviewLayer()
        requestPermissionAndConfigure()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // MARK: – Setup

    private func setupPreviewLayer() {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        previewLayer = layer
    }

    private func requestPermissionAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            sessionQueue.async { self.configureAndStart() }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted { self?.sessionQueue.async { self?.configureAndStart() } }
            }
        default:
            break   // denied / restricted — LiveCameraContainerView shows error
        }
    }

    private func configureAndStart() {
        guard !session.isRunning, session.inputs.isEmpty else { return }
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video, position: .back),
              let input  = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:
                                    kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: classifyQueue)

        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(output)

        if let conn = output.connection(with: .video) {
            conn.videoOrientation = .portrait
        }

        session.commitConfiguration()
        session.startRunning()
    }

    // MARK: – Still frame extraction

    func stillImage(from pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ci = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cg = ciContext.createCGImage(ci, from: ci.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

// MARK: – Sample buffer delegate

extension LiveCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        let now = CACurrentMediaTime()
        guard now - lastClassifyTime >= classifyInterval else { return }
        lastClassifyTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        guard let (label, confidence) = classifier.classify(pixelBuffer: pixelBuffer) else { return }

        // Only capture a still when there's a usable prediction (save memory otherwise)
        let image = confidence >= 0.60 ? stillImage(from: pixelBuffer) : nil

        frameDelegate?.didClassify(label: label, confidence: confidence, capturedImage: image)
    }
}

// MARK: – SwiftUI representable

/// Full-screen live camera preview.
/// Does NOT observe LiveScanViewModel directly — all updates flow through the closure
/// to avoid re-creating the view controller on every ~5 fps publish cycle.
struct LiveCameraPreviewView: UIViewControllerRepresentable {

    /// Called on a background thread for each classified frame.
    let onClassification: (String, Float, UIImage?) -> Void

    /// True when a rear wide camera is available (false on Simulator).
    static var isCameraAvailable: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
    }

    func makeUIViewController(context: Context) -> LiveCameraViewController {
        let vc = LiveCameraViewController()
        vc.frameDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: LiveCameraViewController,
                                context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onClassification: onClassification) }

    // MARK: – Coordinator

    final class Coordinator: NSObject, LiveFrameDelegate {
        let onClassification: (String, Float, UIImage?) -> Void
        init(onClassification: @escaping (String, Float, UIImage?) -> Void) {
            self.onClassification = onClassification
        }
        func didClassify(label: String, confidence: Float, capturedImage: UIImage?) {
            onClassification(label, confidence, capturedImage)
        }
    }
}
