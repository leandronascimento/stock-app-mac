import Foundation

struct YahooQuoteResponse: Codable {
    let quoteResponse: QuoteResponse
    
    struct QuoteResponse: Codable {
        let result: [Quote]
        let error: String?
    }
    
    struct Quote: Codable {
        let symbol: String
        let regularMarketPrice: Double
        let regularMarketChangePercent: Double?
    }
}

class PriceService {
    static let shared = PriceService()
    private init() {}
    
    func fetchPrices(for tickers: [String]) async throws -> [String: Double] {
        guard !tickers.isEmpty else { return [:] }
        
        let symbols = tickers.map { ticker in
            let upperTicker = ticker.uppercased()
            // Indices like ^BVSP already have the prefix
            if upperTicker.hasPrefix("^") { return upperTicker }
            
            // Check if it's already a Yahoo-style symbol (e.g. MSFT, PETR4.SA)
            if upperTicker.contains(".") { return upperTicker }
            
            // Brazilian Stocks (e.g. PETR4, ITUB4, BCFF11, MSFT34) usually follow this pattern:
            // 4 Uppercase letters followed by 1 or 2 digits.
            let b3Regex = try? NSRegularExpression(pattern: "^[A-Z]{4}[0-9]{1,2}$")
            let range = NSRange(location: 0, length: upperTicker.utf16.count)
            if b3Regex?.firstMatch(in: upperTicker, options: [], range: range) != nil {
                return "\(upperTicker).SA"
            }
            
            // Default to US or as-is (e.g. AAPL, SQQQ)
            return upperTicker
        }.joined(separator: ",")
        
        let urlString = "https://query1.finance.yahoo.com/v7/finance/quote?symbols=\(symbols)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        // More robust User-Agent to avoid 429 blocks
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
             if httpResponse.statusCode == 429 {
                 print("Yahoo Finance Rate Limited (429)")
                 // We could potentially retry with an alternative endpoint if needed
             }
             throw URLError(.init(rawValue: httpResponse.statusCode))
        }
        
        let jsonResponse = try JSONDecoder().decode(YahooQuoteResponse.self, from: data)
        
        var result: [String: Double] = [:]
        for quote in jsonResponse.quoteResponse.result {
            // Map back to original ticker (remove .SA)
            let rawTicker = quote.symbol.replacingOccurrences(of: ".SA", with: "")
            result[rawTicker] = quote.regularMarketPrice
            // Also store with symbol for safety
            result[quote.symbol] = quote.regularMarketPrice
        }
        
        return result
    }
}
