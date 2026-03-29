import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingDeleteAllAlert = false
    
    var body: some View {
        let active = appState.positions.filter { $0.quantity.rounded(toPlaces: 4) > 0 }
        
        NavigationStack {
            VStack(spacing: 0) {
                if !active.isEmpty {
                    PortfolioSummaryCard(positions: active)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }
                
                Group {
                    if appState.positions.isEmpty {
                        ContentUnavailableView(
                            "Carteira vazia",
                            systemImage: "chart.pie",
                            description: Text("Adicione operações para ver sua carteira")
                        )
                    } else {
                        if active.isEmpty {
                            ContentUnavailableView(
                                "Nenhum ativo",
                                systemImage: "chart.bar",
                                description: Text("Suas posições atuais aparecerão aqui")
                            )
                        } else {
                            List {
                                ForEach(active) { position in
                                    PortfolioRowView(position: position)
                                }
                            }
                            .listStyle(.plain)
                            .background(DesignSystem.Colors.background)
                            .scrollContentBackground(.hidden)
                        }
                    }
                }
            }
            .navigationTitle("Carteira (\(active.count))")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        showingDeleteAllAlert = true
                    } label: {
                        Label("Limpar Tudo", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .toolbarBackground(DesignSystem.Colors.background)
            .toolbarBackground(.visible)
            .background(DesignSystem.Colors.background)
            .onAppear {
                appState.loadAll()
                print("Active positions: \(active.map { $0.ticker })")
            }
            .confirmationDialog(
                "Apagar todas as transações?",
                isPresented: $showingDeleteAllAlert,
                titleVisibility: .visible
            ) {
                Button("Sim, Apagar Tudo", role: .destructive) {
                    try? appState.repo.deleteAll()
                    appState.loadAll()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta ação é irreversível e apagará todo o seu histórico cadastrado.")
            }
        }
    }
}

struct PortfolioSummaryCard: View {
    @EnvironmentObject var appState: AppState
    let positions: [Position]
    
    private var totalEquity: Double {
        positions.reduce(0) { sum, pos in
            let price = appState.prices[pos.ticker] ?? pos.averagePrice
            return sum + (price * pos.quantity)
        }
    }
    
    private var totalCost: Double {
        positions.reduce(0) { $0 + ($1.quantity * $1.averagePrice) }
    }
    
    private var totalGain: Double {
        totalEquity - totalCost
    }
    
    private var totalYield: Double {
        guard totalCost > 0 else { return 0 }
        return (totalEquity / totalCost - 1) * 100
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PATRIMÔNIO ATUAL")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text(BRLFormatter.currency(totalEquity))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("RENTABILIDADE")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    HStack(spacing: 4) {
                        Text(totalYield >= 0 ? "+" : "")
                        Text(String(format: "%.2f%%", totalYield))
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(totalYield >= 0 ? DesignSystem.Colors.positive : DesignSystem.Colors.negative)
                }
            }
            
            HStack {
                HStack(spacing: 4) {
                    Text("Lucro Total:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text(BRLFormatter.currency(totalGain))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(totalGain >= 0 ? DesignSystem.Colors.positive : DesignSystem.Colors.negative)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Custo de Aquisição:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text(BRLFormatter.currency(totalCost))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color.blue.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.1), lineWidth: 1)
        )
    }
}

extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
