import XCTest
@testable import StockApp

final class TaxCalculatorTests: XCTestCase {
    
    func test_exemption_under_20k() {
        let transactions = [
            Transaction(ticker: "PETR4", date: "2024-03-01", operation: "BUY", quantity: 100, unitPrice: 10, totalCost: 0, createdAt: "1", updatedAt: "1"),
            Transaction(ticker: "PETR4", date: "2024-03-10", operation: "SELL", quantity: 100, unitPrice: 20, totalCost: 0, createdAt: "2", updatedAt: "2")
        ]
        
        let reports = TaxCalculator.calculate(transactions: transactions)
        XCTAssertEqual(reports.count, 1)
        let r = reports[0]
        XCTAssertEqual(r.totalSold, 2000)
        XCTAssertTrue(r.isExempt)
        XCTAssertEqual(r.taxDue, 0)
    }
    
    func test_tax_over_20k() {
        let transactions = [
            Transaction(ticker: "PETR4", date: "2024-03-01", operation: "BUY", quantity: 1000, unitPrice: 10, totalCost: 0, createdAt: "1", updatedAt: "1"),
            Transaction(ticker: "PETR4", date: "2024-03-10", operation: "SELL", quantity: 1000, unitPrice: 30, totalCost: 0, createdAt: "2", updatedAt: "2")
        ]
        
        let reports = TaxCalculator.calculate(transactions: transactions)
        XCTAssertEqual(reports.count, 1)
        let r = reports[0]
        XCTAssertEqual(r.totalSold, 30000)
        XCTAssertFalse(r.isExempt)
        XCTAssertEqual(r.netGain, 20000)
        XCTAssertEqual(r.taxDue, 3000) // 15% of 20000
    }
    
    func test_loss_carryforward() {
        let transactions = [
            // Month 1: Loss of 5000
            Transaction(ticker: "PETR4", date: "2024-01-01", operation: "BUY", quantity: 1000, unitPrice: 10, totalCost: 0, createdAt: "1", updatedAt: "1"),
            Transaction(ticker: "PETR4", date: "2024-01-10", operation: "SELL", quantity: 1000, unitPrice: 5, totalCost: 0, createdAt: "2", updatedAt: "2"),
            
            // Month 2: Gain of 10000 (over 20k sold)
            Transaction(ticker: "PETR4", date: "2024-02-01", operation: "BUY", quantity: 1000, unitPrice: 10, totalCost: 0, createdAt: "3", updatedAt: "3"),
            Transaction(ticker: "PETR4", date: "2024-02-10", operation: "SELL", quantity: 1000, unitPrice: 21, totalCost: 0, createdAt: "4", updatedAt: "4")
        ]
        
        let reports = TaxCalculator.calculate(transactions: transactions).sorted(by: { $0.month < $1.month })
        XCTAssertEqual(reports.count, 2)
        
        // Month 1
        XCTAssertEqual(reports[0].netGain, -5000)
        XCTAssertEqual(reports[0].taxDue, 0)
        
        // Month 2
        let r2 = reports[1]
        XCTAssertEqual(r2.netGain, 11000) // (21-10)*1000
        XCTAssertEqual(r2.carriedLoss, 5000)
        XCTAssertEqual(r2.taxableGain, 6000) // 11000 - 5000
        XCTAssertEqual(r2.taxDue, 900) // 15% of 6000
    }
}
