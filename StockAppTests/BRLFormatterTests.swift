import XCTest
@testable import StockApp

final class BRLFormatterTests: XCTestCase {

    func test_currency_formatsWithCommaDecimal() {
        XCTAssertEqual(BRLFormatter.currency(1234.56), "R$ 1.234,56")
    }

    func test_currency_zero() {
        XCTAssertEqual(BRLFormatter.currency(0), "R$ 0,00")
    }

    func test_currency_smallValue() {
        XCTAssertEqual(BRLFormatter.currency(9.57), "R$ 9,57")
    }

    func test_decimal_twoPlaces() {
        XCTAssertEqual(BRLFormatter.decimal(30.0), "30,00")
    }

    func test_decimal_commaDecimal() {
        XCTAssertEqual(BRLFormatter.decimal(7.14), "7,14")
    }

    func test_quantity_integerShowsNoDecimal() {
        XCTAssertEqual(BRLFormatter.quantity(100), "100")
    }

    func test_quantity_fractionalShowsDecimal() {
        XCTAssertEqual(BRLFormatter.quantity(35.5), "35,5")
    }

    func test_date_brazilianFormat() {
        XCTAssertEqual(BRLFormatter.date("2024-01-10"), "10/01/2024")
    }

    func test_date_invalidReturnsOriginal() {
        XCTAssertEqual(BRLFormatter.date("not-a-date"), "not-a-date")
    }
}
