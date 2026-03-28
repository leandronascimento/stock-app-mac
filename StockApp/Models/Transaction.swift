import Foundation
import GRDB

struct Transaction: Identifiable, Hashable, Sendable {
    var id: String = UUID().uuidString
    var ticker: String
    var date: String           // "YYYY-MM-DD"
    var operation: String      // "BUY" | "SELL"
    var quantity: Double
    var unitPrice: Double
    var totalCost: Double      // brokerage fees only
    var broker: String?
    var category: String?
    var notes: String?
    var createdAt: String      // ISO 8601
    var updatedAt: String      // ISO 8601
}

extension Transaction: Codable {
    enum CodingKeys: String, CodingKey {
        case id, ticker, date, operation, quantity, unitPrice, totalCost
        case broker, category, notes, createdAt, updatedAt
    }
}

extension Transaction: FetchableRecord, PersistableRecord {
    static let databaseTableName = "transactions"
}
