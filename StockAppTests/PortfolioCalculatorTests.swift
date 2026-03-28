import XCTest
@testable import StockApp

final class PortfolioCalculatorTests: XCTestCase {

    private func makeTx(
        ticker: String = "PETR4",
        date: String = "2024-01-10",
        operation: String = "BUY",
        quantity: Double,
        unitPrice: Double,
        totalCost: Double = 0
    ) -> Transaction {
        Transaction(
            ticker: ticker,
            date: date,
            operation: operation,
            quantity: quantity,
            unitPrice: unitPrice,
            totalCost: totalCost,
            broker: nil,
            category: nil,
            notes: nil,
            createdAt: date + "T10:00:00Z",
            updatedAt: date + "T10:00:00Z"
        )
    }

    func test_singleBuy_producesCorrectPosition() {
        let txs = [makeTx(quantity: 100, unitPrice: 30.0)]
        let positions = PortfolioCalculator.calculate(transactions: txs)
        XCTAssertEqual(positions.count, 1)
        XCTAssertEqual(positions[0].ticker, "PETR4")
        XCTAssertEqual(positions[0].quantity, 100)
        XCTAssertEqual(positions[0].averagePrice, 30.0, accuracy: 0.001)
        XCTAssertEqual(positions[0].totalInvested, 3000.0, accuracy: 0.001)
    }

    func test_multipleBuys_computesWeightedAverage() {
        let txs = [
            makeTx(date: "2024-01-10", quantity: 100, unitPrice: 30.0),
            makeTx(date: "2024-02-10", quantity: 100, unitPrice: 40.0),
        ]
        let positions = PortfolioCalculator.calculate(transactions: txs)
        XCTAssertEqual(positions[0].averagePrice, 35.0, accuracy: 0.001)
        XCTAssertEqual(positions[0].quantity, 200)
    }

    func test_buyCost_includedInAveragePrice() {
        // 100 shares at 10.00, fee = 10.00
        // cost basis = 100*10 + 10 = 1010
        // averagePrice = 1010 / 100 = 10.10
        let txs = [makeTx(quantity: 100, unitPrice: 10.0, totalCost: 10.0)]
        let positions = PortfolioCalculator.calculate(transactions: txs)
        XCTAssertEqual(positions[0].averagePrice, 10.10, accuracy: 0.001)
    }

    func test_sell_doesNotChangeAveragePrice() {
        let txs = [
            makeTx(date: "2024-01-10", operation: "BUY",  quantity: 100, unitPrice: 30.0),
            makeTx(date: "2024-03-01", operation: "SELL", quantity: 50,  unitPrice: 40.0),
        ]
        let positions = PortfolioCalculator.calculate(transactions: txs)
        XCTAssertEqual(positions[0].quantity, 50)
        XCTAssertEqual(positions[0].averagePrice, 30.0, accuracy: 0.001)
    }

    func test_sell_computesRealizedGain() {
        // buy 100 @ 30, sell 50 @ 40 → gain = (40-30)*50 = 500
        let txs = [
            makeTx(date: "2024-01-10", operation: "BUY",  quantity: 100, unitPrice: 30.0),
            makeTx(date: "2024-03-01", operation: "SELL", quantity: 50,  unitPrice: 40.0),
        ]
        let positions = PortfolioCalculator.calculate(transactions: txs)
        XCTAssertEqual(positions[0].realizedGain, 500.0, accuracy: 0.001)
    }

    func test_fullSell_removesPositionFromResult() {
        let txs = [
            makeTx(date: "2024-01-10", operation: "BUY",  quantity: 100, unitPrice: 30.0),
            makeTx(date: "2024-03-01", operation: "SELL", quantity: 100, unitPrice: 40.0),
        ]
        let positions = PortfolioCalculator.calculate(transactions: txs)
        XCTAssertEqual(positions.count, 0)
    }

    func test_multipleTickers_calculatedIndependently() {
        let txs = [
            makeTx(ticker: "PETR4", date: "2024-01-10", quantity: 100, unitPrice: 30.0),
            makeTx(ticker: "VALE3", date: "2024-01-15", quantity: 50,  unitPrice: 60.0),
        ]
        let positions = PortfolioCalculator.calculate(transactions: txs)
        XCTAssertEqual(positions.count, 2)
        let petr = positions.first { $0.ticker == "PETR4" }!
        let vale = positions.first { $0.ticker == "VALE3" }!
        XCTAssertEqual(petr.averagePrice, 30.0, accuracy: 0.001)
        XCTAssertEqual(vale.averagePrice, 60.0, accuracy: 0.001)
    }

    func test_emptyTransactions_returnsEmpty() {
        let positions = PortfolioCalculator.calculate(transactions: [])
        XCTAssertEqual(positions.count, 0)
    }

    func test_unsortedInput_sortedChronologicallyBeforeCalculation() {
        // Same two buys, reversed in array order — result must be identical
        // because calculator sorts by date internally
        let txs = [
            makeTx(date: "2024-02-10", quantity: 100, unitPrice: 40.0),
            makeTx(date: "2024-01-10", quantity: 100, unitPrice: 30.0),
        ]
        let positions = PortfolioCalculator.calculate(transactions: txs)
        XCTAssertEqual(positions[0].averagePrice, 35.0, accuracy: 0.001)
    }
}
