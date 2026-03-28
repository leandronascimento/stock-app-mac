enum PortfolioCalculator {
    static func calculate(transactions: [Transaction]) -> [Position] {
        var state: [String: PositionState] = [:]

        let sorted = transactions.sorted {
            if $0.date != $1.date { return $0.date < $1.date }
            return $0.createdAt < $1.createdAt
        }

        for tx in sorted {
            var pos = state[tx.ticker] ?? PositionState()

            switch tx.operation {
            case "BUY":
                let newCostBasis = (pos.quantity * pos.averagePrice)
                                 + (tx.quantity * tx.unitPrice)
                                 + tx.totalCost
                let newQuantity = pos.quantity + tx.quantity
                pos.averagePrice = newQuantity > 0 ? newCostBasis / newQuantity : 0
                pos.quantity = newQuantity

            case "SELL":
                let gain = (tx.unitPrice - pos.averagePrice) * tx.quantity - tx.totalCost
                pos.quantity -= tx.quantity
                pos.realizedGain += gain

            default:
                break
            }

            state[tx.ticker] = pos
        }

        return state.compactMap { ticker, pos in
            guard pos.quantity > 0 else { return nil }
            return Position(
                ticker: ticker,
                quantity: pos.quantity,
                averagePrice: pos.averagePrice,
                totalInvested: pos.quantity * pos.averagePrice,
                realizedGain: pos.realizedGain
            )
        }
    }

    private struct PositionState {
        var quantity: Double = 0
        var averagePrice: Double = 0
        var realizedGain: Double = 0
    }
}
