import SwiftUI

@main
struct StockAppApp: App {
    @StateObject private var appState = AppState(database: AppDatabase.shared)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
