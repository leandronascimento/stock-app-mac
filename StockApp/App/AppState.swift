import Foundation
internal import Combine

@MainActor
final class AppState: ObservableObject {
    let repo: TransactionRepository
    let metadataRepo: TickerMetadataRepository

    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var positions: [Position] = []
    @Published private(set) var taxReports: [MonthlyTaxReport] = []
    @Published private(set) var metadata: [String: TickerMetadata] = [:]
    @Published var prices: [String: Double] = [:]
    @Published var errorMessage: String?

    init(database: AppDatabase) {
        print("Caminho do Banco: ", FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!)
        self.repo = TransactionRepository(db: database.dbQueue)
        self.metadataRepo = TickerMetadataRepository(db: database.dbQueue)
    }

    func loadAll() {
        do {
            transactions = try repo.fetchAll()
            metadata = try metadataRepo.fetchAll().reduce(into: [:]) { $0[$1.ticker] = $1 }
            positions = PortfolioCalculator.calculate(transactions: transactions)
            taxReports = TaxCalculator.calculate(transactions: transactions)
            refreshPrices()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveMetadata(_ meta: TickerMetadata) throws {
        try metadataRepo.save(meta)
        loadAll()
    }

    func refreshPrices() {
        let activeTickers = positions.filter { $0.quantity > 1e-6 }.map { $0.ticker }
        guard !activeTickers.isEmpty else { return }
        
        Task {
            do {
                let newPrices = try await PriceService.shared.fetchPrices(for: activeTickers)
                self.prices = newPrices
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func add(_ transaction: Transaction) throws {
        try repo.insert(transaction)
        loadAll()
    }

    func update(_ transaction: Transaction) throws {
        try repo.update(transaction)
        loadAll()
    }

    @discardableResult
    func delete(id: String) throws -> Bool {
        let deleted = try repo.delete(id: id)
        loadAll()
        return deleted
    }
    func previewImport(data: Data) throws -> ImportPreview {
        try CSVImporter.parse(data: data, existing: transactions)
    }

    func importTransactions(_ rows: [ParsedRow]) throws {
        let formatter = ISO8601DateFormatter()
        let baseDate = Date()
        
        for (index, row) in rows.enumerated() {
            // Slightly increment the timestamp for each row to preserve CSV order in tie-breakers
            let timestamp = baseDate.addingTimeInterval(Double(index))
            let createdAt = formatter.string(from: timestamp)
            
            try repo.insert(Transaction(
                ticker: row.ticker,
                date: row.date,
                operation: row.operation,
                quantity: row.quantity,
                unitPrice: row.unitPrice,
                totalCost: row.totalCost,
                broker: row.broker,
                category: row.category,
                notes: row.notes,
                createdAt: createdAt,
                updatedAt: createdAt
            ))
        }
        loadAll()
    }
}
