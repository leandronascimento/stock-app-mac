import Foundation

enum TaxCalculator {
    struct MonthlyData {
        var totalSold: Double = 0
        var netGain: Double = 0
    }
    
    static func calculate(transactions: [Transaction]) -> [MonthlyTaxReport] {
        // 1. Sort transactions by date
        let sorted = transactions.sorted {
            if $0.date != $1.date { return $0.date < $1.date }
            return $0.createdAt < $1.createdAt
        }
        
        // 2. Track average prices and monthly gains
        var avgPrices: [String: Double] = [:]
        var quantities: [String: Double] = [:]
        var monthlyData: [String: MonthlyData] = [:] // Key: "yyyy-MM"
        
        for tx in sorted {
            let ticker = tx.ticker
            let monthKey = String(tx.date.prefix(7)) // "yyyy-MM"
            
            var data = monthlyData[monthKey] ?? MonthlyData()
            
            switch tx.operation {
            case "BUY":
                let currentQty = quantities[ticker] ?? 0
                let currentAvg = avgPrices[ticker] ?? 0
                
                let newQty = currentQty + tx.quantity
                let newCost = (currentQty * currentAvg) + (tx.quantity * tx.unitPrice) + tx.totalCost
                
                quantities[ticker] = newQty
                avgPrices[ticker] = newQty > 0 ? newCost / newQty : 0
                
            case "SELL":
                let currentQty = quantities[ticker] ?? 0
                let currentAvg = avgPrices[ticker] ?? 0
                
                let saleValue = tx.quantity * tx.unitPrice
                let gain = (tx.unitPrice - currentAvg) * tx.quantity - tx.totalCost
                
                data.totalSold += saleValue
                data.netGain += gain
                
                quantities[ticker] = currentQty - tx.quantity
                // Average price doesn't change on sell
                
            default: break
            }
            
            monthlyData[monthKey] = data
        }
        
        // 3. Process months chronologically for loss carryforward
        let sortedMonths = monthlyData.keys.sorted()
        var reports: [MonthlyTaxReport] = []
        var carriedLoss: Double = 0
        
        for monthKey in sortedMonths {
            let data = monthlyData[monthKey]!
            let components = monthKey.split(separator: "-").map { Int($0) ?? 0 }
            let year = components[0]
            let month = components[1]
            
            let isExempt = data.totalSold < 20000
            
            var taxableGain: Double = 0
            var taxDue: Double = 0
            var newCarriedLoss = carriedLoss
            
            if data.netGain < 0 {
                // Loss: add to carried balance
                newCarriedLoss += abs(data.netGain)
            } else if data.netGain > 0 {
                if isExempt {
                    // Profit is exempt, doesn't pay tax, but doesn't reduce carried loss either?
                    // "Ganhos isentos não compensam prejuízos acumulados."
                    taxableGain = 0
                    taxDue = 0
                } else {
                    // Taxable profit: subtract carried loss
                    if data.netGain > carriedLoss {
                        taxableGain = data.netGain - carriedLoss
                        newCarriedLoss = 0
                        taxDue = taxableGain * 0.15
                    } else {
                        taxableGain = 0
                        newCarriedLoss = carriedLoss - data.netGain
                        taxDue = 0
                    }
                }
            }
            
            reports.append(MonthlyTaxReport(
                year: year,
                month: month,
                totalSold: data.totalSold,
                netGain: data.netGain,
                carriedLoss: carriedLoss,
                taxableGain: taxableGain,
                taxDue: taxDue,
                isExempt: isExempt
            ))
            
            carriedLoss = newCarriedLoss
        }
        
        return reports.sorted {
            if $0.year != $1.year { return $0.year > $1.year }
            return $0.month > $1.month
        }
    }
}
