import Foundation
import GRDB

struct Transaction: Identifiable, Codable, Hashable {
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

extension Transaction: FetchableRecord, PersistableRecord {
    static let databaseTableName = "transactions"
}
