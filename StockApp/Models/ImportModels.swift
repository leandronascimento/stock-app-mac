import Foundation

struct ParsedRow: Identifiable {
    let id = UUID()
    let ticker: String
    let date: String        // ISO 8601 "YYYY-MM-DD"
    let operation: String   // "BUY" | "SELL"
    let quantity: Double
    let unitPrice: Double
    let totalCost: Double
    let broker: String?
    let category: String?
    let notes: String?
}

struct ImportError: Identifiable {
    let id = UUID()
    let rowNumber: Int
    let rawContent: String
    let reason: String
}

struct ImportPreview {
    let valid: [ParsedRow]
    let errors: [ImportError]
    let duplicates: [ParsedRow]  // subset of valid; rows that match an existing transaction
}
