import GRDB
import Foundation

final class AppDatabase {
    let dbQueue: DatabaseQueue

    static let shared: AppDatabase = {
        do {
            return try AppDatabase()
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }()

    init(dbQueue: DatabaseQueue? = nil) throws {
        if let queue = dbQueue {
            self.dbQueue = queue
        } else {
            let folder = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let dbPath = folder.appendingPathComponent("stockapp.sqlite").path
            self.dbQueue = try DatabaseQueue(path: dbPath)
        }
        try runMigrations()
    }

    private func runMigrations() throws {
        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1_create_transactions") { db in
            try db.create(table: "transactions") { t in
                t.column("id", .text).primaryKey()
                t.column("ticker", .text).notNull()
                t.column("date", .text).notNull()
                t.column("operation", .text).notNull()
                t.column("quantity", .double).notNull()
                t.column("unitPrice", .double).notNull()
                t.column("totalCost", .double).notNull()
                t.column("broker", .text)
                t.column("category", .text)
                t.column("notes", .text)
                t.column("createdAt", .text).notNull()
                t.column("updatedAt", .text).notNull()
            }
            try db.create(index: "idx_transactions_ticker",
                          on: "transactions", columns: ["ticker"])
            try db.create(index: "idx_transactions_date",
                          on: "transactions", columns: ["date"])
        }

        migrator.registerMigration("v2_create_ticker_metadata") { db in
            try db.create(table: "ticker_metadata") { t in
                t.column("ticker", .text).primaryKey()
                t.column("cnpj", .text)
                t.column("name", .text)
            }
            try db.create(index: "idx_ticker_metadata_cnpj",
                          on: "ticker_metadata", columns: ["cnpj"])
        }

        try migrator.migrate(dbQueue)
    }
}
