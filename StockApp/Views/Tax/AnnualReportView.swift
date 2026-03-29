import SwiftUI

struct AnnualReportView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date()) - 1
    @State private var editingMetadata: TickerMetadata?
    
    let years = (2020...(Calendar.current.component(.year, from: Date()))).reversed()
    
    var entries: [AnnualReportEntry] {
        AnnualReportService.generate(year: selectedYear, 
                                    transactions: appState.transactions, 
                                    metadata: appState.metadata)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Modern Year Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(years, id: \.self) { year in
                            Button {
                                selectedYear = year
                            } label: {
                                Text(String(year))
                                    .font(.system(size: 14, weight: selectedYear == year ? .bold : .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedYear == year ? Color.blue : Color.gray.opacity(0.1))
                                    .foregroundColor(selectedYear == year ? .white : DesignSystem.Colors.primaryText)
                                    .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .background(DesignSystem.Colors.background)
                
                List {
                    if entries.isEmpty {
                        ContentUnavailableView(
                            "Sem posições em \(String(selectedYear))",
                            systemImage: "calendar.badge.exclamationmark",
                            description: Text("Nenhuma ação em carteira no dia 31/12/\(String(selectedYear))")
                        )
                    } else {
                        ForEach(entries) { entry in
                            AnnualReportRow(entry: entry) {
                                editingMetadata = appState.metadata[entry.ticker] ?? TickerMetadata(ticker: entry.ticker)
                            }
                        }
                        
                        Section {
                            Text("Atenção: Este relatório é uma estimativa gerada com base nas transações cadastradas. Verifique os valores com seu contador antes de enviar a declaração de IR.")
                                .font(.system(size: 11))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .padding(.vertical, 20)
                                .multilineTextAlignment(.center)
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .background(DesignSystem.Colors.background)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Bens e Direitos")
            .toolbarBackground(DesignSystem.Colors.background)
            .toolbarBackground(.visible)
            .background(DesignSystem.Colors.background)
            .sheet(item: $editingMetadata) { meta in
                EditMetadataView(metadata: meta)
            }
        }
    }
}

struct AnnualReportRow: View {
    let entry: AnnualReportEntry
    let onEdit: () -> Void
    
    var body: some View {
        DesignSystem.RowCard {
            VStack(alignment: .leading, spacing: 10) {
                // Header: Ticker, Name and Edit
                HStack(alignment: .center, spacing: 12) {
                    DesignSystem.TickerBadge(ticker: entry.ticker)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.ticker)
                            .font(.system(size: 14, weight: .bold))
                        if let name = entry.companyName {
                            Text(name)
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        ReportFieldSmall(label: "CNPJ", value: entry.cnpj ?? "---", isWarning: entry.cnpj == nil)
                        ReportFieldSmall(label: "QTD", value: entry.formattedQuantity)
                    }
                    
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.blue.opacity(0.8))
                            .padding(6)
                            .background(Color.blue.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Discrimination and Copy
                HStack(spacing: 12) {
                    Text(entry.discrimination)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primaryText.opacity(0.8))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.04))
                        .cornerRadius(6)
                    
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(entry.discrimination, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                // Footer: Total Value
                HStack {
                    Text("VALOR TOTAL")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.6))
                    Spacer()
                    Text(BRLFormatter.currency(entry.totalValue))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                .padding(.top, 2)
            }
        }
    }
}

struct ReportFieldSmall: View {
    let label: String
    let value: String
    var isWarning: Bool = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.7))
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isWarning ? .red : DesignSystem.Colors.primaryText)
        }
    }
}

struct ReportField: View {
    let label: String
    let value: String
    var isWarning: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(DesignSystem.Colors.secondaryText)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isWarning ? .red : DesignSystem.Colors.primaryText)
        }
    }
}

struct EditMetadataView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State var metadata: TickerMetadata
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Dados da Empresa") {
                    TextField("Nome Razão Social", text: Binding(
                        get: { metadata.name ?? "" },
                        set: { metadata.name = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("CNPJ", text: Binding(
                        get: { metadata.cnpj ?? "" },
                        set: { metadata.cnpj = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
            .navigationTitle("Editar \(metadata.ticker)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        try? appState.saveMetadata(metadata)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}
