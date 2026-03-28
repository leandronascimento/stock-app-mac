import Foundation

@MainActor
final class AppState: ObservableObject {
    let repo: TransactionRepository

    init(database: AppDatabase) {
        self.repo = TransactionRepository(db: database.dbQueue)
    }
}
