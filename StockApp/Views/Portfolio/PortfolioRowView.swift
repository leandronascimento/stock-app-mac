import SwiftUI

struct PortfolioRowView: View {
    @EnvironmentObject var appState: AppState
    let position: Position

    private var currentPrice: Double? {
        appState.prices[position.ticker]
    }

    private var currentValue: Double {
        (currentPrice ?? position.averagePrice) * position.quantity
    }

    private var totalGainValue: Double {
        currentValue - (position.quantity * position.averagePrice)
    }

    private var percentageGain: Double {
        guard let current = currentPrice, position.averagePrice > 0 else { return 0 }
        return (current / position.averagePrice - 1) * 100
    }

    private var companyName: String? {
        appState.metadata[position.ticker]?.name
    }

    var body: some View {
        DesignSystem.RowCard {
            HStack(alignment: .center, spacing: 16) {
                // 1. Ticker and Company
                HStack(spacing: 8) {
                    DesignSystem.TickerBadge(ticker: position.ticker)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(position.ticker)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        if let name = companyName {
                            Text(name)
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(width: 120, alignment: .leading)
                
                // 2. Quantity and Avg Price
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(BRLFormatter.quantity(position.quantity))
                            .fontWeight(.bold)
                        Text("un.")
                            .font(.system(size: 9))
                    }
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("PM: \(BRLFormatter.decimal(position.averagePrice))")
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                // 3. Current Valuation
                VStack(alignment: .trailing, spacing: 1) {
                    Text(BRLFormatter.currency(currentValue))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    if let price = currentPrice {
                        Text("Atu: \(BRLFormatter.decimal(price))")
                            .font(.system(size: 10))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    } else {
                        Text("---")
                            .font(.system(size: 10))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                
                // 4. Performance
                VStack(alignment: .trailing, spacing: 2) {
                    DesignSystem.RowPill(value: percentageGain)
                    
                    Text(BRLFormatter.currency(totalGainValue))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(totalGainValue >= 0 ? DesignSystem.Colors.positive : DesignSystem.Colors.negative)
                }
                .frame(width: 80, alignment: .trailing)
            }
        }
    }
}
