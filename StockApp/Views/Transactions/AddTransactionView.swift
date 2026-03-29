import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private let existingTransaction: Transaction?

    @State private var ticker: String
    @State private var date: Date
    @State private var operation: String
    @State private var quantityText: String
    @State private var unitPriceText: String
    @State private var totalCostText: String
    @State private var broker: String
    @State private var notes: String
    @State private var errorMessage: String?

    init(transaction: Transaction? = nil) {
        self.existingTransaction = transaction

        if let tx = transaction {
            let isoParser = DateFormatter()
            isoParser.dateFormat = "yyyy-MM-dd"
            isoParser.locale = Locale(identifier: "en_US_POSIX")
            let parsedDate = isoParser.date(from: tx.date) ?? Date()

            _ticker        = State(initialValue: tx.ticker)
            _date          = State(initialValue: parsedDate)
            _operation     = State(initialValue: tx.operation)
            _quantityText  = State(initialValue: String(tx.quantity))
            _unitPriceText = State(initialValue: String(tx.unitPrice))
            _totalCostText = State(initialValue: tx.totalCost > 0 ? String(tx.totalCost) : "")
            _broker        = State(initialValue: tx.broker ?? "")
            _notes         = State(initialValue: tx.notes ?? "")
        } else {
            _ticker        = State(initialValue: "")
            _date          = State(initialValue: Date())
            _operation     = State(initialValue: "BUY")
            _quantityText  = State(initialValue: "")
            _unitPriceText = State(initialValue: "")
            _totalCostText = State(initialValue: "")
            _broker        = State(initialValue: "")
            _notes         = State(initialValue: "")
        }
    }

    private var isValid: Bool {
        !ticker.trimmingCharacters(in: .whitespaces).isEmpty &&
        parseDouble(quantityText) > 0 &&
        parseDouble(unitPriceText) > 0
    }

    private func parseDouble(_ text: String) -> Double {
        Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private func save() {
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd"
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = isoFormatter.string(from: date)
        let now = ISO8601DateFormatter().string(from: Date())

        var tx = existingTransaction ?? Transaction(
            ticker: "",
            date: "",
            operation: "",
            quantity: 0,
            unitPrice: 0,
            totalCost: 0,
            broker: nil,
            category: "Ações",
            notes: nil,
            createdAt: now,
            updatedAt: now
        )

        tx.ticker    = ticker.uppercased().trimmingCharacters(in: .whitespaces)
        tx.date      = dateString
        tx.operation = operation
        tx.quantity  = parseDouble(quantityText)
        tx.unitPrice = parseDouble(unitPriceText)
        tx.totalCost = parseDouble(totalCostText)
        tx.broker    = broker.isEmpty ? nil : broker
        tx.notes     = notes.isEmpty ? nil : notes
        tx.updatedAt = now

        do {
            if existingTransaction != nil {
                try appState.update(tx)
            } else {
                try appState.add(tx)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ativo") {
                    TextField("Ticker (ex: PETR4)", text: $ticker)
                        #if os(iOS)
                        .textInputAutocapitalization(.characters)
                        #endif
                        .autocorrectionDisabled()

                    Picker("Operação", selection: $operation) {
                        Text("Compra (C)").tag("BUY")
                        Text("Venda (V)").tag("SELL")
                    }
                    .pickerStyle(.segmented)

                    DatePicker("Data", selection: $date, displayedComponents: .date)
                }

                Section("Valores") {
                    TextField("Quantidade", text: $quantityText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("Preço unitário (R$)", text: $unitPriceText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("Custo/corretagem (R$)", text: $totalCostText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }

                Section("Detalhes (opcional)") {
                    TextField("Corretora", text: $broker)
                    TextField("Observação", text: $notes)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(existingTransaction != nil ? "Editar Operação" : "Nova Operação")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }
}
