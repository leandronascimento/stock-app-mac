import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction

    private var operationColor: Color {
        transaction.operation == "BUY" ? Color.blue : Color.orange
    }

    private var operationLabel: String {
        transaction.operation == "BUY" ? "C" : "V"
    }

    var body: some View {
        DesignSystem.RowCard {
            HStack(alignment: .center, spacing: 16) {
                // 1. Operation and Ticker
                HStack(spacing: 12) {
                    DesignSystem.TickerBadge(ticker: transaction.ticker)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text(transaction.operation == "BUY" ? "Compra" : "Venda")
                                .font(.system(size: 9, weight: .black))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(transaction.operation == "BUY" ? DesignSystem.Colors.positive.opacity(0.12) : Color.orange.opacity(0.12))
                                .foregroundColor(transaction.operation == "BUY" ? DesignSystem.Colors.positive : Color.orange)
                                .cornerRadius(2)
                            
                            Text(transaction.ticker)
                                .font(.system(size: 13, weight: .bold))
                        }
                        
                        Text(BRLFormatter.date(transaction.date))
                            .font(.system(size: 10))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                .frame(width: 140, alignment: .leading)
                
                Spacer()
                
                // 2. Value and Details
                VStack(alignment: .trailing, spacing: 1) {
                    Text(BRLFormatter.currency(transaction.quantity * transaction.unitPrice))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("\(BRLFormatter.quantity(transaction.quantity)) × \(BRLFormatter.decimal(transaction.unitPrice))")
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
    }
}
