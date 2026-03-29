import GRDB

final class TransactionRepository {
    private let db: DatabaseQueue

    init(db: DatabaseQueue) {
        self.db = db
    }

    func fetchAll() throws -> [Transaction] {
        try db.read { db in
            try Transaction.order(Column("date").asc, Column("createdAt").asc).fetchAll(db)
        }
    }

    func fetchAll(upTo date: String) throws -> [Transaction] {
        try db.read { db in
            try Transaction
                .filter(Column("date") <= date)
                .order(Column("date"), Column("createdAt"))
                .fetchAll(db)
        }
    }

    func insert(_ transaction: Transaction) throws {
        try db.write { db in
            try transaction.insert(db)
        }
    }

    func update(_ transaction: Transaction) throws {
        try db.write { db in
            try transaction.update(db)
        }
    }

    @discardableResult
    func delete(id: String) throws -> Bool {
        try db.write { db in
            try Transaction.deleteOne(db, key: id)
        }
    }

    func deleteAll() throws {
        try db.write { db in
            try db.execute(sql: "DELETE FROM transactions")
        }
    }
}
