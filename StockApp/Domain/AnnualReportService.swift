import Foundation

struct AnnualReportEntry: Identifiable {
    var id: String { ticker }
    let ticker: String
    let quantity: Double
    let averagePrice: Double
    let totalValue: Double
    let companyName: String?
    let cnpj: String?
    
    var formattedQuantity: String {
        BRLFormatter.quantity(quantity)
    }
    
    var discrimination: String {
        let avgPriceStr = BRLFormatter.decimal(averagePrice)
        return "\(formattedQuantity) ações de \(ticker) ao preço médio de \(avgPriceStr)"
    }
}

enum AnnualReportService {
    static func generate(year: Int, transactions: [Transaction], metadata: [String: TickerMetadata]) -> [AnnualReportEntry] {
        let endDate = "\(year)-12-31"
        let historicalTxs = transactions.filter { $0.date <= endDate }
        let positions = PortfolioCalculator.calculate(transactions: historicalTxs)
        
        return positions
            .filter { $0.quantity > 1e-6 }
            .map { pos in
                let meta = metadata[pos.ticker]
                return AnnualReportEntry(
                    ticker: pos.ticker,
                    quantity: pos.quantity,
                    averagePrice: pos.averagePrice,
                    totalValue: pos.totalInvested,
                    companyName: meta?.name,
                    cnpj: meta?.cnpj
                )
            }
            .sorted { $0.ticker < $1.ticker }
    }
}
