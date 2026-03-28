struct Position: Identifiable {
    var id: String { ticker }
    let ticker: String
    let quantity: Double
    let averagePrice: Double
    let totalInvested: Double   // quantity × averagePrice
    let realizedGain: Double    // accumulated gain from closed sells
}
