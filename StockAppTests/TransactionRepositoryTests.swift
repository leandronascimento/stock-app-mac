import XCTest
import GRDB
@testable import StockApp

final class TransactionRepositoryTests: XCTestCase {
    var repo: TransactionRepository!

    override func setUp() async throws {
        let db = try AppDatabase(dbQueue: DatabaseQueue())
        repo = TransactionRepository(db: db.dbQueue)
    }

    private func makeTx(
        ticker: String = "PETR4",
        date: String = "2024-01-10",
        operation: String = "BUY",
        quantity: Double = 100,
        unitPrice: Double = 30.0,
        totalCost: Double = 10.0
    ) -> Transaction {
        Transaction(
            ticker: ticker,
            date: date,
            operation: operation,
            quantity: quantity,
            unitPrice: unitPrice,
            totalCost: totalCost,
            broker: "XP",
            category: "Ações",
            notes: nil,
            createdAt: "2024-01-10T10:00:00Z",
            updatedAt: "2024-01-10T10:00:00Z"
        )
    }

    func test_insert_and_fetchAll() throws {
        let tx = makeTx()
        try repo.insert(tx)
        let all = try repo.fetchAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].id, tx.id)
        XCTAssertEqual(all[0].ticker, "PETR4")
    }

    func test_fetchAll_sortedByDateThenCreatedAt() throws {
        // Primary sort: date ASC
        let tx1 = makeTx(date: "2024-03-01")
        let tx2 = makeTx(date: "2024-01-10")
        try repo.insert(tx1)
        try repo.insert(tx2)
        let all = try repo.fetchAll()
        XCTAssertEqual(all[0].date, "2024-01-10")
        XCTAssertEqual(all[1].date, "2024-03-01")
    }

    func test_fetchAll_sortedByCreatedAt_whenSameDate() throws {
        // Secondary sort: createdAt ASC when date is equal
        var tx1 = makeTx(date: "2024-01-10")
        var tx2 = makeTx(date: "2024-01-10")
        tx1.createdAt = "2024-01-10T09:00:00Z"
        tx2.createdAt = "2024-01-10T11:00:00Z"
        try repo.insert(tx1)
        try repo.insert(tx2)
        let all = try repo.fetchAll()
        XCTAssertEqual(all[0].id, tx1.id)
        XCTAssertEqual(all[1].id, tx2.id)
    }

    func test_delete_nonExistentId_returnsFalse() throws {
        let deleted = try repo.delete(id: "nonexistent-id")
        XCTAssertFalse(deleted)
    }

    func test_fetchAll_upToDate_excludesLater() throws {
        let tx1 = makeTx(date: "2024-01-10")
        let tx2 = makeTx(date: "2024-06-15")
        try repo.insert(tx1)
        try repo.insert(tx2)
        let filtered = try repo.fetchAll(upTo: "2024-12-31")
        XCTAssertEqual(filtered.count, 2)
        let filtered2 = try repo.fetchAll(upTo: "2024-03-01")
        XCTAssertEqual(filtered2.count, 1)
        XCTAssertEqual(filtered2[0].date, "2024-01-10")
    }

    func test_update_changesFields() throws {
        var tx = makeTx()
        try repo.insert(tx)
        tx.notes = "updated note"
        try repo.update(tx)
        let all = try repo.fetchAll()
        XCTAssertEqual(all[0].notes, "updated note")
    }

    func test_delete_removesTransaction() throws {
        let tx = makeTx()
        try repo.insert(tx)
        try repo.delete(id: tx.id)
        let all = try repo.fetchAll()
        XCTAssertEqual(all.count, 0)
    }
}
