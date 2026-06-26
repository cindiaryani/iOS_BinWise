import Vision
import CoreML
import UIKit

/// Performs on-device waste classification using BinWise_Training 1.mlmodel.
/// Uses Vision framework for automatic image preprocessing and Core ML inference.
final class ClassifierService: ObservableObject {

    private var visionModel: VNCoreMLModel?
    @Published private(set) var isModelLoaded: Bool = false

    init() { loadModel() }

    // MARK: - Model loading

    private func loadModel() {
        // Xcode may compile the model with the space preserved or replaced by underscore.
        let candidates = ["BinWise_Training 1", "BinWise_Training_1"]
        guard let url = candidates.lazy
            .compactMap({ Bundle.main.url(forResource: $0, withExtension: "mlmodelc") })
            .first else {
            print("[ClassifierService] ⚠️ BinWise_Training 1.mlmodelc not found in bundle.")
            return
        }
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine
            let ml = try MLModel(contentsOf: url, configuration: config)
            visionModel = try VNCoreMLModel(for: ml)
            isModelLoaded = true
        } catch {
            print("[ClassifierService] ⚠️ Model failed to load: \(error.localizedDescription)")
        }
    }

    // MARK: - Photo classification (async, for photo picker flow)

    func classify(image: UIImage) async throws -> ClassificationResult {
        guard isModelLoaded, let visionModel else {
            throw AppError.modelNotAvailable
        }
        guard let cgImage = image.cgImage else {
            throw AppError.invalidImage
        }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: visionModel) { req, error in
                if let error {
                    continuation.resume(throwing: AppError.classificationFailed(error.localizedDescription))
                    return
                }
                guard let obs = req.results as? [VNClassificationObservation],
                      let _ = obs.first else {
                    continuation.resume(throwing: AppError.noResultsFound)
                    return
                }
                let sorted = obs.sorted { $0.confidence > $1.confidence }
                let result = ClassificationResult(
                    label: sorted[0].identifier,
                    confidence: Double(sorted[0].confidence),
                    allResults: sorted.prefix(3).map {
                        ClassificationCandidate(label: $0.identifier,
                                                confidence: Double($0.confidence))
                    }
                )
                continuation.resume(returning: result)
            }
            request.imageCropAndScaleOption = .centerCrop
            do {
                try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            } catch {
                continuation.resume(throwing: AppError.classificationFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - Live camera frame classification (sync, called from camera queue)

    func classifyFrame(_ pixelBuffer: CVPixelBuffer) -> ClassificationResult? {
        guard isModelLoaded, let visionModel else { return nil }
        var result: ClassificationResult?
        let request = VNCoreMLRequest(model: visionModel) { req, _ in
            guard let obs = req.results as? [VNClassificationObservation],
                  !obs.isEmpty else { return }
            let sorted = obs.sorted { $0.confidence > $1.confidence }
            result = ClassificationResult(
                label: sorted[0].identifier,
                confidence: Double(sorted[0].confidence),
                allResults: sorted.prefix(3).map {
                    ClassificationCandidate(label: $0.identifier,
                                            confidence: Double($0.confidence))
                }
            )
        }
        request.imageCropAndScaleOption = .centerCrop
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .right,
                                            options: [:])
        try? handler.perform([request])
        return result
    }
}
