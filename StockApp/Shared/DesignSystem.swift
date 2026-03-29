import SwiftUI

enum DesignSystem {
    enum Colors {
        static let background = Color(white: 0.98)
        static let surface = Color.white
        static let border = Color(white: 0.9)
        static let secondaryText = Color(white: 0.45)
        static let primaryText = Color(red: 55/255, green: 53/255, blue: 47/255)
        
        static let positive = Color(red: 46/255, green: 184/255, blue: 114/255)
        static let negative = Color(red: 229/255, green: 57/255, blue: 53/255)
        
        static func forTicker(_ ticker: String) -> Color {
            let palette: [Color] = [
                Color(red: 0.20, green: 0.47, blue: 0.81), // Blue
                Color(red: 0.36, green: 0.72, blue: 0.36), // Green
                Color(red: 0.95, green: 0.61, blue: 0.07), // Orange
                Color(red: 0.61, green: 0.35, blue: 0.71), // Purple
                Color(red: 0.17, green: 0.24, blue: 0.31), // Dark Blue
                Color(red: 0.10, green: 0.74, blue: 0.61)  // Teal
            ]
            
            // Stable hash using DJB2 algorithm
            var hash = 5381
            for scalar in ticker.unicodeScalars {
                hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
            }
            
            let index = abs(hash) % palette.count
            return palette[index]
        }
    }
    
    struct TickerBadge: View {
        let ticker: String
        var body: some View {
            Text(ticker)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 44, height: 22)
                .background(Colors.forTicker(ticker))
                .cornerRadius(4)
        }
    }
    
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }
    
    enum Radius {
        static let standard: CGFloat = 8
    }
    
    struct RowCard<Content: View>: View {
        let content: () -> Content
        
        init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content
        }
        
        var body: some View {
            content()
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Colors.surface)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.08), lineWidth: 1)
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
    }
    
    struct RowPill: View {
        let value: Double
        var showSign: Bool = true
        
        var body: some View {
            HStack(spacing: 2) {
                if showSign {
                    Text(value >= 0 ? "+" : "")
                }
                Text(String(format: "%.2f%%", value))
            }
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                (value >= 0 ? Colors.positive : Colors.negative)
                    .opacity(0.12)
            )
            .foregroundColor(value >= 0 ? Colors.positive : Colors.negative)
            .cornerRadius(4)
        }
    }
    
    struct CardModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .background(Colors.surface)
                .cornerRadius(Radius.standard)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.standard)
                        .stroke(Colors.border, lineWidth: 1)
                )
        }
    }
}

extension View {
    func notionCard() -> some View {
        self.modifier(DesignSystem.CardModifier())
    }
}
