import SwiftUI

struct TaxReportView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            List {
                if appState.taxReports.isEmpty {
                    ContentUnavailableView(
                        "Sem relatórios",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Venda seus ativos para gerar relatórios fiscais")
                    )
                } else {
                    ForEach(appState.taxReports) { report in
                        TaxReportRow(report: report)
                    }
                }
                
                Section {
                    Text("Atenção: Este cálculo é uma estimativa para fins informativos. Consulte um contador para sua declaração oficial de IR.")
                        .font(.system(size: 11))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("IR Mensal")
            .listStyle(.plain)
            .toolbarBackground(DesignSystem.Colors.background)
            .toolbarBackground(.visible)
            .background(DesignSystem.Colors.background)
            .scrollContentBackground(.hidden)
        }
    }
}

struct TaxReportRow: View {
    let report: MonthlyTaxReport
    
    var body: some View {
        DesignSystem.RowCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(report.monthName) \(String(report.year))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        if report.isExempt {
                            Text("ISENTO")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("VENDIDO")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.7))
                            Text(BRLFormatter.currency(report.totalSold))
                                .font(.system(size: 11, weight: .medium))
                        }
                        
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("GANHO")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.7))
                            Text(BRLFormatter.currency(report.netGain))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(report.netGain >= 0 ? DesignSystem.Colors.positive : DesignSystem.Colors.negative)
                        }
                        
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("IR DEVIDO")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.7))
                            Text(BRLFormatter.currency(report.taxDue))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(report.taxDue > 0 ? DesignSystem.Colors.negative : DesignSystem.Colors.primaryText)
                        }
                    }
                }
                
                if report.carriedLoss > 0 {
                    Divider().opacity(0.3)
                    HStack {
                        Text("Prejuízo acumulado abatido")
                            .font(.system(size: 10))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        Spacer()
                        Text(BRLFormatter.currency(report.carriedLoss))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.negative)
                    }
                    .padding(.top, 2)
                }
            }
        }
    }
}
