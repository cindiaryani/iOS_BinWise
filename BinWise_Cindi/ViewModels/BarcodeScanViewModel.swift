import Foundation

/// Drives the barcode → Open Food Facts → Advisor pipeline.
@MainActor
final class BarcodeScanViewModel: ObservableObject {

    // MARK: – Phase

    enum Phase: Equatable {
        case scanning                // waiting for barcode from camera
        case fetching                // querying Open Food Facts
        case ready                   // packaging info found; ready for Advisor
        case notFound(String)        // product or packaging not found
        case error(String)           // network or parsing failure
    }

    // MARK: – State

    @Published var phase: Phase = .scanning
    @Published var detectedBarcode  = ""
    @Published var productName      = ""
    @Published var packagingSummary = ""

    private let offService = OpenFoodFactsService()

    // MARK: – Public interface

    /// Called as soon as the barcode scanner detects a code.
    func processBarcode(_ barcode: String) {
        guard phase == .scanning else { return }
        detectedBarcode = barcode
        phase = .fetching
        Task { await fetch(barcode: barcode) }
    }

    /// Resets all state so the view can scan a new barcode.
    func retry() {
        phase           = .scanning
        detectedBarcode = ""
        productName     = ""
        packagingSummary = ""
    }

    /// Builds an `AgentAssessment` from the fetched packaging data.
    /// The category is a best-effort guess; the Advisor agent provides the final answer.
    func makeAssessment() -> AgentAssessment {
        let itemDescription = packagingSummary.isEmpty
            ? productName
            : "\(productName) — packaging materials: \(packagingSummary)"
        return AgentAssessment(
            item: itemDescription,
            category: "recyclable",
            certainty: "medium",
            needsClarification: false,
            clarifyingQuestion: nil
        )
    }

    // MARK: – Private

    private func fetch(barcode: String) async {
        do {
            let result      = try await offService.fetchPackaging(barcode: barcode)
            productName     = result.productName
            packagingSummary = result.packagingSummary
            phase           = .ready
        } catch let e as OFFError {
            switch e {
            case .notFound:
                phase = .notFound(
                    "Barcode \"\(barcode)\" was not found in Open Food Facts.\n" +
                    "Try scanning the packaging label instead."
                )
            case .noPackagingData(let name):
                phase = .notFound(
                    "No packaging data available for \"\(name)\".\n" +
                    "Try the OCR label scanner for more detail."
                )
            default:
                phase = .error(e.localizedDescription ?? "Unknown error")
            }
        } catch {
            phase = .error(error.localizedDescription)
        }
    }
}
