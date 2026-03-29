import Foundation

struct MonthlyTaxReport: Identifiable {
    var id: String { "\(year)-\(month)" }
    let year: Int
    let month: Int
    
    let totalSold: Double          // Gross value sold in month
    let netGain: Double            // Gain/loss in month (after costs)
    let carriedLoss: Double        // Loss balance from previous months
    let taxableGain: Double        // Gain after compensation
    let taxDue: Double             // Tax to pay (15%)
    let isExempt: Bool             // True if sales < 20k for Ações
    
    var monthName: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: year, month: month)) ?? Date()
        return fmt.string(from: date).capitalized
    }
}
