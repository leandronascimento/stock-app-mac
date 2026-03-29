import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            Group {
                if appState.positions.isEmpty {
                    ContentUnavailableView(
                        "Carteira vazia",
                        systemImage: "chart.pie",
                        description: Text("Adicione operações para ver sua carteira")
                    )
                } else {
                    List(appState.positions) { position in
                        PortfolioRowView(position: position)
                    }
                }
            }
            .navigationTitle("Carteira")
        }
    }
}
