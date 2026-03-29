import Foundation

enum CSVImporter {

    enum ParseError: LocalizedError {
        case unreadableFile
        case missingHeaders([String])

        var errorDescription: String? {
            switch self {
            case .unreadableFile:
                return "Não foi possível ler o arquivo CSV"
            case .missingHeaders(let cols):
                return "Colunas ausentes no CSV: \(cols.joined(separator: ", "))"
            }
        }
    }

    // MARK: - Public API

    nonisolated static func parse(data: Data, existing: [Transaction]) throws -> ImportPreview {
        guard let content = String(data: data, encoding: .utf8)
                         ?? String(data: data, encoding: .isoLatin1),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw ParseError.unreadableFile
        }

        let lines = content
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let headerLine = lines.first else {
            throw ParseError.missingHeaders([])
        }

        let rawHeaders = headerLine
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

        let colIndex = Dictionary(
            rawHeaders.enumerated().map { ($1, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let required = ["código ativo", "data operação", "operação c/v",
                        "quantidade", "preço unitário", "custo"]
        let missing = required.filter { colIndex[$0] == nil }
        guard missing.isEmpty else { throw ParseError.missingHeaders(missing) }

        var valid: [ParsedRow] = []
        var errors: [ImportError] = []

        for (offset, line) in lines.dropFirst().enumerated() {
            let rowNumber = offset + 2 // 1-based; header = row 1
            let cols = line
                .components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            func col(_ name: String) -> String? {
                guard let idx = colIndex[name], idx < cols.count else { return nil }
                return cols[idx].isEmpty ? nil : cols[idx]
            }

            // --- Required fields ---

            guard let ticker = col("código ativo") else {
                errors.append(ImportError(rowNumber: rowNumber, rawContent: line, reason: "Ticker vazio"))
                continue
            }

            guard let rawDate = col("data operação"),
                  let date = parseDate(rawDate)
            else {
                errors.append(ImportError(rowNumber: rowNumber, rawContent: line,
                    reason: "Data inválida: \(col("data operação") ?? "-")"))
                continue
            }

            guard let rawOp = col("operação c/v"),
                  let operation = mapOperation(rawOp)
            else {
                errors.append(ImportError(rowNumber: rowNumber, rawContent: line,
                    reason: "Operação inválida: \(col("operação c/v") ?? "-")"))
                continue
            }

            guard let rawQty = col("quantidade"),
                  let quantity = parseNumber(rawQty),
                  quantity > 0
            else {
                errors.append(ImportError(rowNumber: rowNumber, rawContent: line,
                    reason: "Quantidade inválida: \(col("quantidade") ?? "-")"))
                continue
            }

            guard let rawPrice = col("preço unitário"),
                  let unitPrice = parseNumber(rawPrice),
                  unitPrice > 0
            else {
                errors.append(ImportError(rowNumber: rowNumber, rawContent: line,
                    reason: "Preço inválido: \(col("preço unitário") ?? "-")"))
                continue
            }

            let totalCost: Double
            if let rawCost = col("custo"), let cost = parseNumber(rawCost) {
                guard cost >= 0 else {
                    errors.append(ImportError(rowNumber: rowNumber, rawContent: line,
                        reason: "Custo negativo: \(rawCost)"))
                    continue
                }
                totalCost = cost
            } else {
                totalCost = 0
            }

            valid.append(ParsedRow(
                ticker: ticker.uppercased(),
                date: date,
                operation: operation,
                quantity: quantity,
                unitPrice: unitPrice,
                totalCost: totalCost,
                broker: col("corretora"),
                category: col("categoria"),
                notes: col("observação")
            ))
        }

        // Duplicate detection: flag rows that match an existing transaction
        let existingKeys = Set(existing.map {
            DupKey(ticker: $0.ticker, date: $0.date,
                   operation: $0.operation, quantity: $0.quantity, unitPrice: $0.unitPrice)
        })
        let duplicates = valid.filter {
            existingKeys.contains(DupKey(ticker: $0.ticker, date: $0.date,
                                         operation: $0.operation, quantity: $0.quantity, unitPrice: $0.unitPrice))
        }

        return ImportPreview(valid: valid, errors: errors, duplicates: duplicates)
    }

    // MARK: - Helpers (internal so tests can call directly)

    static func parseDate(_ raw: String) -> String? {
        let parts = raw.lowercased().components(separatedBy: "/")
        guard parts.count == 3,
              let day   = Int(parts[0].trimmingCharacters(in: .whitespaces)),
              let month = monthMap[parts[1].trimmingCharacters(in: .whitespaces)],
              let year2 = Int(parts[2].trimmingCharacters(in: .whitespaces))
        else { return nil }
        return String(format: "%04d-%02d-%02d", 2000 + year2, month, day)
    }

    static func parseNumber(_ raw: String) -> Double? {
        let cleaned = raw
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }

    static func mapOperation(_ raw: String) -> String? {
        switch raw.trimmingCharacters(in: .whitespaces).uppercased() {
        case "C": return "BUY"
        case "V": return "SELL"
        default:  return nil
        }
    }

    // MARK: - Private

    private static let monthMap: [String: Int] = [
        "jan.": 1, "fev.": 2, "mar.": 3, "abr.": 4,
        "mai.": 5, "jun.": 6, "jul.": 7, "ago.": 8,
        "set.": 9, "out.": 10, "nov.": 11, "dez.": 12
    ]

    private struct DupKey: Hashable {
        let ticker: String
        let date: String
        let operation: String
        let quantity: Double
        let unitPrice: Double
    }
}
