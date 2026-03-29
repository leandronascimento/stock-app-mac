import XCTest
import GRDB
@testable import StockApp

@MainActor
final class AppStateTests: XCTestCase {
    var state: AppState!

    override func setUp() async throws {
        let db = try AppDatabase(dbQueue: DatabaseQueue())
        state = AppState(database: db)
    }

    private func makeTx(
        ticker: String = "PETR4",
        date: String = "2024-01-10",
        operation: String = "BUY",
        quantity: Double = 100,
        unitPrice: Double = 30.0
    ) -> Transaction {
        Transaction(
            ticker: ticker,
            date: date,
            operation: operation,
            quantity: quantity,
            unitPrice: unitPrice,
            totalCost: 0,
            broker: nil,
            category: "Ações",
            notes: nil,
            createdAt: date + "T10:00:00Z",
            updatedAt: date + "T10:00:00Z"
        )
    }

    func test_initialState_isEmpty() {
        XCTAssertTrue(state.transactions.isEmpty)
        XCTAssertTrue(state.positions.isEmpty)
    }

    func test_loadAll_populatesTransactions() throws {
        try state.add(makeTx())
        state.loadAll()
        XCTAssertEqual(state.transactions.count, 1)
    }

    func test_add_insertsAndRefreshes() throws {
        try state.add(makeTx())
        XCTAssertEqual(state.transactions.count, 1)
    }

    func test_add_computesPosition() throws {
        try state.add(makeTx(quantity: 100, unitPrice: 30.0))
        XCTAssertEqual(state.positions.count, 1)
        XCTAssertEqual(state.positions[0].ticker, "PETR4")
        XCTAssertEqual(state.positions[0].averagePrice, 30.0, accuracy: 0.001)
    }

    func test_delete_removesTransactionAndRefreshes() throws {
        let tx = makeTx()
        try state.add(tx)
        XCTAssertEqual(state.transactions.count, 1)
        try state.delete(id: tx.id)
        XCTAssertEqual(state.transactions.count, 0)
        XCTAssertEqual(state.positions.count, 0)
    }

    func test_update_changesTransactionAndRefreshes() throws {
        var tx = makeTx()
        try state.add(tx)
        tx.notes = "updated"
        try state.update(tx)
        XCTAssertEqual(state.transactions[0].notes, "updated")
    }

    func test_fullSell_removesPosition() throws {
        try state.add(makeTx(operation: "BUY",  quantity: 100, unitPrice: 30.0))
        try state.add(makeTx(date: "2024-03-01", operation: "SELL", quantity: 100, unitPrice: 40.0))
        XCTAssertEqual(state.positions.count, 0)
    }
}
