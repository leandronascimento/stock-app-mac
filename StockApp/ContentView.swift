import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            PortfolioView()
                .tabItem {
                    Label("Carteira", systemImage: "chart.pie.fill")
                }
            TransactionListView()
                .tabItem {
                    Label("Operações", systemImage: "list.bullet")
                }
        }
        .task {
            appState.loadAll()
        }
    }
}
