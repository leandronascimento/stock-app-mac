import SwiftUI

struct PortfolioRowView: View {
    let position: Position

    private var gainColor: Color {
        position.realizedGain >= 0 ? .green : .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(position.ticker)
                    .font(.headline)
                Spacer()
                Text(BRLFormatter.currency(position.totalInvested))
                    .font(.headline)
            }
            HStack {
                Text("\(BRLFormatter.quantity(position.quantity)) ações · PM: R$ \(BRLFormatter.decimal(position.averagePrice))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if position.realizedGain != 0 {
                    Text(BRLFormatter.currency(position.realizedGain))
                        .font(.caption)
                        .foregroundStyle(gainColor)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
