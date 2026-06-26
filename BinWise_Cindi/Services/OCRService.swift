import Vision
import UIKit

/// On-device text recognition for packaging labels.
/// Uses VNRecognizeTextRequest at accurate quality with English + Simplified Chinese.
final class OCRService {

    /// Recognises all text lines in `image` and returns them in reading order.
    /// - Throws: `OCRError.badImage` if the image has no CGImage backing.
    func recognizeText(in image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else { throw OCRError.badImage }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { req, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let lines = (req.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    ?? []
                continuation.resume(returning: lines)
            }
            request.recognitionLevel        = .accurate
            request.recognitionLanguages    = ["en-US", "zh-Hans"]
            request.usesLanguageCorrection  = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: – Errors

enum OCRError: Error, LocalizedError {
    case badImage
    case noTextFound
    case noMaterialFound

    var errorDescription: String? {
        switch self {
        case .badImage:        return "Could not process the selected image."
        case .noTextFound:     return "No text was found in the image."
        case .noMaterialFound: return "No recycling codes or material labels were detected."
        }
    }
}
