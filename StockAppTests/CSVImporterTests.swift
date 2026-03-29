import XCTest
@testable import StockApp

final class CSVImporterTests: XCTestCase {

    // Helper: build pipe-delimited CSV Data
    private func makeCSV(header: String = defaultHeader, rows: [String]) -> Data {
        let content = ([header] + rows).joined(separator: "\n")
        return Data(content.utf8)
    }

    private static let defaultHeader =
        "Código Ativo|Data operação|Categoria|Operação C/V|Quantidade|Preço unitário|Custo|Moeda|Corretora|Observação"

    // MARK: - parseDate

    func test_parseDate_standardFormat() {
        XCTAssertEqual(CSVImporter.parseDate("25/jul./19"), "2019-07-25")
        XCTAssertEqual(CSVImporter.parseDate("01/jan./20"), "2020-01-01")
        XCTAssertEqual(CSVImporter.parseDate("31/dez./23"), "2023-12-31")
    }

    func test_parseDate_allTwelveMonths() {
        let months = ["jan.", "fev.", "mar.", "abr.", "mai.", "jun.",
                      "jul.", "ago.", "set.", "out.", "nov.", "dez."]
        for (i, month) in months.enumerated() {
            let result = CSVImporter.parseDate("15/\(month)/22")
            XCTAssertEqual(result, String(format: "2022-%02d-15", i + 1), "Failed for month: \(month)")
        }
    }

    func test_parseDate_invalidReturnsNil() {
        XCTAssertNil(CSVImporter.parseDate(""))
        XCTAssertNil(CSVImporter.parseDate("2024-01-10"))
        XCTAssertNil(CSVImporter.parseDate("25/xxx/19"))
        XCTAssertNil(CSVImporter.parseDate("abc"))
    }

    // MARK: - parseNumber

    func test_parseNumber_commaDecimal() {
        XCTAssertEqual(CSVImporter.parseNumber("7,14"), 7.14)
        XCTAssertEqual(CSVImporter.parseNumber("99,96"), 99.96)
    }

    func test_parseNumber_thousandsSeparator() {
        XCTAssertEqual(CSVImporter.parseNumber("1.234,56"), 1234.56)
        XCTAssertEqual(CSVImporter.parseNumber("10.000,00"), 10000.00)
    }

    func test_parseNumber_integer() {
        XCTAssertEqual(CSVImporter.parseNumber("14"), 14.0)
        XCTAssertEqual(CSVImporter.parseNumber("100"), 100.0)
    }

    func test_parseNumber_invalidReturnsNil() {
        XCTAssertNil(CSVImporter.parseNumber("abc"))
        XCTAssertNil(CSVImporter.parseNumber(""))
    }

    // MARK: - mapOperation

    func test_mapOperation_C_returnsBUY() {
        XCTAssertEqual(CSVImporter.mapOperation("C"), "BUY")
        XCTAssertEqual(CSVImporter.mapOperation("c"), "BUY")
    }

    func test_mapOperation_V_returnsSELL() {
        XCTAssertEqual(CSVImporter.mapOperation("V"), "SELL")
        XCTAssertEqual(CSVImporter.mapOperation("v"), "SELL")
    }

    func test_mapOperation_unknown_returnsNil() {
        XCTAssertNil(CSVImporter.mapOperation("B"))
        XCTAssertNil(CSVImporter.mapOperation("S"))
        XCTAssertNil(CSVImporter.mapOperation(""))
    }

    // MARK: - parse: valid rows

    func test_parse_singleValidRow_allFieldsMapped() throws {
        let csv = makeCSV(rows: ["BHIA3|25/jul./19|Ações|C|14|7,14|99,96|BRL|CLEAR|Antes Agrupamento"])
        let preview = try CSVImporter.parse(data: csv, existing: [])

        XCTAssertEqual(preview.valid.count, 1)
        XCTAssertEqual(preview.errors.count, 0)
        let row = preview.valid[0]
        XCTAssertEqual(row.ticker, "BHIA3")
        XCTAssertEqual(row.date, "2019-07-25")
        XCTAssertEqual(row.operation, "BUY")
        XCTAssertEqual(row.quantity, 14.0, accuracy: 0.001)
        XCTAssertEqual(row.unitPrice, 7.14, accuracy: 0.001)
        XCTAssertEqual(row.totalCost, 99.96, accuracy: 0.001)
        XCTAssertEqual(row.broker, "CLEAR")
        XCTAssertEqual(row.category, "Ações")
        XCTAssertEqual(row.notes, "Antes Agrupamento")
    }

    func test_parse_columnOrderIndependent() throws {
        // Columns in reversed order from default — parser must use header names, not positions
        let header = "Operação C/V|Corretora|Quantidade|Código Ativo|Custo|Preço unitário|Data operação|Categoria|Moeda|Observação"
        let row    = "C|CLEAR|14|BHIA3|99,96|7,14|25/jul./19|Ações|BRL|nota"
        let csv = makeCSV(header: header, rows: [row])
        let preview = try CSVImporter.parse(data: csv, existing: [])

        XCTAssertEqual(preview.valid.count, 1)
        XCTAssertEqual(preview.valid[0].ticker, "BHIA3")
        XCTAssertEqual(preview.valid[0].quantity, 14.0, accuracy: 0.001)
    }

    func test_parse_tickerIsUppercased() throws {
        let csv = makeCSV(rows: ["petr4|10/jan./24|Ações|C|100|30,00|0||XP|"])
        let preview = try CSVImporter.parse(data: csv, existing: [])
        XCTAssertEqual(preview.valid[0].ticker, "PETR4")
    }

    func test_parse_sellOperation() throws {
        let csv = makeCSV(rows: ["PETR4|10/jan./24|Ações|V|50|35,00|5||XP|"])
        let preview = try CSVImporter.parse(data: csv, existing: [])
        XCTAssertEqual(preview.valid[0].operation, "SELL")
    }

    // MARK: - parse: fault tolerance

    func test_parse_emptyTicker_rowSkipped() throws {
        let csv = makeCSV(rows: ["|25/jul./19|Ações|C|14|7,14|0||CLEAR|"])
        let preview = try CSVImporter.parse(data: csv, existing: [])
        XCTAssertEqual(preview.valid.count, 0)
        XCTAssertEqual(preview.errors.count, 1)
        XCTAssertEqual(preview.errors[0].rowNumber, 2) // header = row 1
    }

    func test_parse_badDate_rowSkipped() throws {
        let csv = makeCSV(rows: ["PETR4|2024-01-10|Ações|C|100|30,00|0||XP|"])
        let preview = try CSVImporter.parse(data: csv, existing: [])
        XCTAssertEqual(preview.valid.count, 0)
        XCTAssertEqual(preview.errors.count, 1)
    }

    func test_parse_badOperation_rowSkipped() throws {
        let csv = makeCSV(rows: ["PETR4|10/jan./24|Ações|X|100|30,00|0||XP|"])
        let preview = try CSVImporter.parse(data: csv, existing: [])
        XCTAssertEqual(preview.valid.count, 0)
        XCTAssertEqual(preview.errors.count, 1)
    }

    func test_parse_zeroQuantity_rowSkipped() throws {
        let csv = makeCSV(rows: ["PETR4|10/jan./24|Ações|C|0|30,00|0||XP|"])
        let preview = try CSVImporter.parse(data: csv, existing: [])
        XCTAssertEqual(preview.valid.count, 0)
        XCTAssertEqual(preview.errors.count, 1)
    }

    func test_parse_zeroPrice_rowSkipped() throws {
        let csv = makeCSV(rows: ["PETR4|10/jan./24|Ações|C|100|0|0||XP|"])
        let preview = try CSVImporter.parse(data: csv, existing: [])
        XCTAssertEqual(preview.valid.count, 0)
        XCTAssertEqual(preview.errors.count, 1)
    }

    func test_parse_negativeCost_rowSkipped() throws {
        let csv = makeCSV(rows: ["PETR4|10/jan./24|Ações|C|100|30,00|-5||XP|"])
        let preview = try CSVImporter.parse(data: csv, existing: [])
        XCTAssertEqual(preview.valid.count, 0)
        XCTAssertEqual(preview.errors.count, 1)
    }

    func test_parse_mixedRows_validAndInvalid() throws {
        let csv = makeCSV(rows: [
            "PETR4|10/jan./24|Ações|C|100|30,00|0||XP|",
            "|10/jan./24|Ações|C|100|30,00|0||XP|",    // empty ticker
            "VALE3|15/mar./24|Ações|V|50|60,00|5||XP|"
        ])
        let preview = try CSVImporter.parse(data: csv, existing: [])
        XCTAssertEqual(preview.valid.count, 2)
        XCTAssertEqual(preview.errors.count, 1)
        XCTAssertEqual(preview.errors[0].rowNumber, 3)
    }

    // MARK: - parse: duplicate detection

    func test_parse_duplicateDetection() throws {
        let existing = [Transaction(
            ticker: "PETR4", date: "2024-01-10", operation: "BUY",
            quantity: 100, unitPrice: 30.0, totalCost: 0,
            broker: nil, category: nil, notes: nil,
            createdAt: "2024-01-10T10:00:00Z", updatedAt: "2024-01-10T10:00:00Z"
        )]
        let csv = makeCSV(rows: [
            "PETR4|10/jan./24|Ações|C|100|30,00|0||XP|", // duplicate
            "VALE3|15/mar./24|Ações|C|50|60,00|0||XP|"   // new
        ])
        let preview = try CSVImporter.parse(data: csv, existing: existing)
        XCTAssertEqual(preview.valid.count, 2)
        XCTAssertEqual(preview.duplicates.count, 1)
        XCTAssertEqual(preview.duplicates[0].ticker, "PETR4")
    }

    // MARK: - parse: fatal errors

    func test_parse_missingRequiredHeaders_throws() {
        let csv = makeCSV(header: "Código Ativo|Data operação", rows: [])
        XCTAssertThrowsError(try CSVImporter.parse(data: csv, existing: [])) { error in
            guard case CSVImporter.ParseError.missingHeaders = error else {
                XCTFail("Expected missingHeaders, got \(error)")
                return
            }
        }
    }

    func test_parse_emptyFile_throws() {
        let csv = Data() // empty → no header line
        XCTAssertThrowsError(try CSVImporter.parse(data: csv, existing: []))
    }
}
