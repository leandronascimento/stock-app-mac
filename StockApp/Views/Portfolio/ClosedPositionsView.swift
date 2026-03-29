import SwiftUI

struct ClosedPositionsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            Group {
                let closed = appState.positions.filter { $0.quantity.rounded(toPlaces: 4) <= 0 }
                
                if closed.isEmpty {
                    ContentUnavailableView(
                        "Sem posições encerradas",
                        systemImage: "archivebox",
                        description: Text("Venda seus ativos para vê-los aqui")
                    )
                } else {
                    List {
                        ForEach(closed) { position in
                            PortfolioRowView(position: position)
                        }
                    }
                    .listStyle(.plain)
                    .background(DesignSystem.Colors.background)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Encerrados")
            .toolbarBackground(DesignSystem.Colors.background)
            .toolbarBackground(.visible)
            .background(DesignSystem.Colors.background)
        }
    }
}
