import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            PortfolioView()
                .tabItem {
                    Label("Carteira", systemImage: "chart.pie.fill")
                }
            ClosedPositionsView()
                .tabItem {
                    Label("Encerrados", systemImage: "archivebox.fill")
                }
            TaxReportView()
                .tabItem {
                    Label("IR Mensal", systemImage: "doc.text.fill")
                }
            AnnualReportView()
                .tabItem {
                    Label("Bens e Direitos", systemImage: "folder.fill")
                }
            TransactionListView()
                .tabItem {
                    Label("Operações", systemImage: "list.bullet")
                }
        }
        .task {
            appState.loadAll()
        }
        .preferredColorScheme(.light)
    }
}
