import Foundation

@MainActor
final class AppState: ObservableObject {
    let repo: TransactionRepository

    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var positions: [Position] = []
    @Published var errorMessage: String?

    init(database: AppDatabase) {
        self.repo = TransactionRepository(db: database.dbQueue)
    }

    func loadAll() {
        do {
            transactions = try repo.fetchAll()
            positions = PortfolioCalculator.calculate(transactions: transactions)
        } catch {
            errorMessage = error.localizedDescription
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
}
