import GRDB
import Foundation

class TickerMetadataRepository {
    private let db: DatabaseQueue

    init(db: DatabaseQueue) {
        self.db = db
    }

    func fetchAll() throws -> [TickerMetadata] {
        try db.read { db in
            try TickerMetadata.fetchAll(db)
        }
    }

    func save(_ metadata: TickerMetadata) throws {
        try db.write { db in
            try metadata.save(db)
        }
    }
}
