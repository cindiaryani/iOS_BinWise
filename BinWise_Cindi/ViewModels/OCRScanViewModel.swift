import UIKit

/// Drives the image → OCR → ResinCode → Advisor pipeline.
@MainActor
final class OCRScanViewModel: ObservableObject {

    // MARK: – Phase

    enum Phase: Equatable {
        case idle                     // no image yet
        case recognizing              // OCR in progress
        case detected(material: String)  // material found
        case noMaterial               // OCR succeeded but no material keyword
        case error(String)            // OCR or image error
    }

    // MARK: – State

    @Published var phase: Phase = .idle
    @Published var capturedImage: UIImage?
    @Published var detectedMaterial = ""

    private let ocr = OCRService()

    // MARK: – Public interface

    /// Runs OCR on `image` to extract recycling / material keywords.
    func processImage(_ image: UIImage) {
        capturedImage = image
        phase         = .recognizing
        Task { await runOCR(on: image) }
    }

    /// Builds an `AgentAssessment` from the detected material keyword.
    /// The Advisor agent will provide the authoritative disposal guidance.
    func makeAssessment() -> AgentAssessment {
        // PVC and PS typically go to "other" in China's classification system;
        // everything else defaults to recyclable as a reasonable starting guess.
        let lower    = detectedMaterial.lowercased()
        let category = (lower.contains("pvc") || lower.contains("ps (")) ? "other" : "recyclable"
        return AgentAssessment(
            item: detectedMaterial,
            category: category,
            certainty: "medium",
            needsClarification: false,
            clarifyingQuestion: nil
        )
    }

    /// Called by live camera when it auto-detects a material — bypasses the OCR step.
    func setDetectedMaterial(_ material: String, image: UIImage?) {
        capturedImage    = image
        detectedMaterial = material
        phase            = .detected(material: material)
    }

    /// Resets state to allow the user to pick a new image.
    func reset() {
        phase           = .idle
        capturedImage   = nil
        detectedMaterial = ""
    }

    // MARK: – Private

    private func runOCR(on image: UIImage) async {
        do {
            let lines = try await ocr.recognizeText(in: image)
            guard !lines.isEmpty else { phase = .noMaterial; return }
            if let material = ResinCodeService.parse(lines) {
                detectedMaterial = material
                phase = .detected(material: material)
            } else {
                phase = .noMaterial
            }
        } catch {
            phase = .error(error.localizedDescription)
        }
    }
}
