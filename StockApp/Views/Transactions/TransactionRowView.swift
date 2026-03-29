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
        HStack(spacing: 12) {
            Text(operationLabel)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(operationColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.ticker)
                    .font(.headline)
                Text(BRLFormatter.date(transaction.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(BRLFormatter.currency(transaction.quantity * transaction.unitPrice))
                    .font(.subheadline)
                Text("\(BRLFormatter.quantity(transaction.quantity)) × R$ \(BRLFormatter.decimal(transaction.unitPrice))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
