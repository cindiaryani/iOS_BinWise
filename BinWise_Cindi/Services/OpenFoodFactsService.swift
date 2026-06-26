import Foundation

// MARK: – Codable wire types

private struct OFFResponse: Decodable {
    let status: Int          // 1 = found, 0 = not found
    let product: OFFProduct?
}

private struct OFFProduct: Decodable {
    let productName: String?
    let packaging: String?
    let packagingTags: [String]?
    let packagingMaterialsTags: [String]?

    enum CodingKeys: String, CodingKey {
        case productName              = "product_name"
        case packaging
        case packagingTags            = "packaging_tags"
        case packagingMaterialsTags   = "packaging_materials_tags"
    }
}

// MARK: – Result

/// Successful lookup result returned to the BarcodeScanViewModel.
struct OFFFetchResult {
    /// Human-readable product name from Open Food Facts.
    let productName: String
    /// Formatted packaging summary (e.g., "PET plastic bottle + Paper label").
    let packagingSummary: String
}

// MARK: – Errors

/// Typed errors from the Open Food Facts lookup layer.
enum OFFError: Error, LocalizedError {
    case notFound
    case noPackagingData(productName: String)
    case networkError(Error)
    case httpError(Int)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Product not found in Open Food Facts."
        case .noPackagingData(let name):
            return "No packaging data available for \"\(name)\"."
        case .networkError(let e):
            return "Network error: \(e.localizedDescription)"
        case .httpError(let code):
            return "Server returned HTTP \(code)."
        case .decodingError(let msg):
            return "Response parsing failed: \(msg)"
        }
    }
}

// MARK: – Service

/// Queries the Open Food Facts v2 API to retrieve packaging materials for a scanned barcode.
///
/// NOTE: Open Food Facts coverage of Chinese local products varies significantly.
/// Always offer the visual-scan fallback when packaging data is absent or incomplete.
final class OpenFoodFactsService {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches packaging materials for `barcode` from Open Food Facts.
    /// - Throws: `OFFError` on network failure, HTTP error, product-not-found, or missing data.
    func fetchPackaging(barcode: String) async throws -> OFFFetchResult {
        let urlString = "https://world.openfoodfacts.org/api/v2/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            throw OFFError.decodingError("Could not build URL for barcode \(barcode)")
        }
        var request = URLRequest(url: url)
        // Open Food Facts asks apps to identify themselves via User-Agent.
        request.setValue("BinWise/1.0 (iOS student project; waste classifier)",
                         forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw OFFError.networkError(error)
        }
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw OFFError.httpError(http.statusCode)
        }

        let decoded: OFFResponse
        do {
            decoded = try JSONDecoder().decode(OFFResponse.self, from: data)
        } catch {
            throw OFFError.decodingError(error.localizedDescription)
        }

        guard decoded.status == 1, let product = decoded.product else {
            throw OFFError.notFound
        }
        let name    = product.productName.flatMap { $0.isEmpty ? nil : $0 } ?? "Unknown product"
        let summary = buildSummary(from: product)
        guard let summary else { throw OFFError.noPackagingData(productName: name) }
        return OFFFetchResult(productName: name, packagingSummary: summary)
    }

    // MARK: – Private

    /// Builds a human-readable packaging string from the most structured field available.
    private func buildSummary(from product: OFFProduct) -> String? {
        // Priority 1: structured material tags (most machine-readable)
        if let tags = product.packagingMaterialsTags, !tags.isEmpty {
            let readable = tags.prefix(4).map { tag in
                tag.replacingOccurrences(of: "en:", with: "")
                   .replacingOccurrences(of: "-", with: " ")
                   .capitalized
            }
            return readable.joined(separator: " + ")
        }
        // Priority 2: free-text packaging field
        if let pkg = product.packaging, !pkg.isEmpty {
            return pkg
        }
        // Priority 3: packaging_tags as last resort
        if let tags = product.packagingTags, !tags.isEmpty {
            let readable = tags.prefix(3).map { tag in
                tag.replacingOccurrences(of: "en:", with: "")
                   .replacingOccurrences(of: "-", with: " ")
                   .capitalized
            }
            return readable.joined(separator: " + ")
        }
        return nil
    }
}
