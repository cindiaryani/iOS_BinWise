import Vision
import CoreML
import CoreVideo

/// Synchronous per-frame classifier for use from AVCaptureVideoDataOutputSampleBufferDelegate.
/// Designed to be called on a background dispatch queue; never touches the main thread.
final class LiveClassifierService {

    private let visionModel: VNCoreMLModel?

    init() {
        let candidates = ["BinWise_Training 1", "BinWise_Training_1"]
        if let url  = candidates.lazy
                        .compactMap({ Bundle.main.url(forResource: $0, withExtension: "mlmodelc") })
                        .first,
           let ml   = try? MLModel(contentsOf: url),
           let vnml = try? VNCoreMLModel(for: ml) {
            visionModel = vnml
        } else {
            visionModel = nil
        }
    }

    /// True when the compiled model file is present in the bundle.
    var isAvailable: Bool { visionModel != nil }

    /// Classifies a pixel buffer and returns the top label + confidence, or nil on failure.
    /// Returns nil when the model is absent — camera keeps running in preview-only mode.
    func classify(pixelBuffer: CVPixelBuffer) -> (label: String, confidence: Float)? {
        guard let model = visionModel else { return nil }
        var topResult: (String, Float)?
        let request = VNCoreMLRequest(model: model) { req, _ in
            guard let obs = req.results as? [VNClassificationObservation],
                  let top = obs.first else { return }
            topResult = (top.identifier, top.confidence)
        }
        request.imageCropAndScaleOption = .centerCrop
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .right,
                                            options: [:])
        try? handler.perform([request])
        return topResult
    }
}
