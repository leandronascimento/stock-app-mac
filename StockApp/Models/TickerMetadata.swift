import Foundation
import GRDB

struct TickerMetadata: Identifiable, Hashable, Sendable, Codable, FetchableRecord, PersistableRecord {
    var id: String { ticker }
    var ticker: String
    var cnpj: String?
    var name: String?
    
    static let databaseTableName = "ticker_metadata"
}
