import Foundation

enum BRLFormatter {
    private static let ptBR = Locale(identifier: "pt_BR")

    static func currency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "R$"
        f.locale = ptBR
        return f.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }

    static func decimal(_ value: Double, places: Int = 2) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = ptBR
        f.minimumFractionDigits = places
        f.maximumFractionDigits = places
        return f.string(from: NSNumber(value: value)) ?? "0,00"
    }

    // Whole numbers → no decimals. Fractions → up to 2 decimal places.
    static func quantity(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = ptBR
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // "YYYY-MM-DD" → "DD/MM/YYYY"
    static func date(_ isoDate: String) -> String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        input.locale = Locale(identifier: "en_US_POSIX")
        guard let d = input.date(from: isoDate) else { return isoDate }
        let output = DateFormatter()
        output.dateFormat = "dd/MM/yyyy"
        return output.string(from: d)
    }
}
