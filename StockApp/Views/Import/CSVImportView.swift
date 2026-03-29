import SwiftUI
import UniformTypeIdentifiers

struct CSVImportView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var isPresented: Bool

    @State private var showFilePicker = false
    @State private var preview: ImportPreview?
    @State private var skipDuplicates = true
    @State private var parseError: String?

    var body: some View {
        NavigationStack {
            if let preview {
                previewContent(preview)
            } else {
                pickPrompt
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handlePickerResult(result)
        }
    }

    // MARK: - Subviews

    private var pickPrompt: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Selecione o arquivo CSV exportado pela corretora")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            if let error = parseError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Button("Selecionar arquivo") {
                showFilePicker = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .navigationTitle("Importar CSV")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { isPresented = false }
            }
        }
    }

    @ViewBuilder
    private func previewContent(_ preview: ImportPreview) -> some View {
        List {
            Section {
                LabeledContent("Operações válidas", value: "\(preview.valid.count)")
                LabeledContent("Linhas com erro", value: "\(preview.errors.count)")
                if !preview.duplicates.isEmpty {
                    LabeledContent("Duplicatas detectadas", value: "\(preview.duplicates.count)")
                    Toggle("Ignorar duplicatas", isOn: $skipDuplicates)
                }
            } header: {
                Text("Resumo")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(.bottom, 8)
                    .textCase(nil)
            }
            .listRowBackground(Color.clear)

            if !preview.errors.isEmpty {
                Section {
                    ForEach(preview.errors) { err in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Linha \(err.rowNumber): \(err.reason)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.negative)
                            Text(err.rawContent)
                                .font(.system(size: 11))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    Text("Erros (\(preview.errors.count))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .textCase(nil)
                }
            }

            Section {
                ForEach(preview.valid) { row in
                    let isDuplicate = preview.duplicates.contains { $0.id == row.id }
                    DesignSystem.RowCard {
                        HStack(alignment: .center, spacing: 16) {
                            // 1. Operation and Ticker
                            HStack(spacing: 8) {
                                DesignSystem.TickerBadge(ticker: row.ticker)
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    HStack(spacing: 6) {
                                        Text(row.operation == "BUY" ? "Compra" : "Venda")
                                            .font(.system(size: 8, weight: .black))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(row.operation == "BUY" ? DesignSystem.Colors.positive.opacity(0.12) : Color.orange.opacity(0.12))
                                            .foregroundColor(row.operation == "BUY" ? DesignSystem.Colors.positive : Color.orange)
                                            .cornerRadius(2)
                                        
                                        Text(row.ticker)
                                            .font(.system(size: 13, weight: .bold))
                                        
                                        if isDuplicate {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundStyle(.orange)
                                                .font(.system(size: 10))
                                        }
                                    }
                                    
                                    Text(BRLFormatter.date(row.date))
                                        .font(.system(size: 10))
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                            }
                            .frame(width: 140, alignment: .leading)
                            
                            Spacer()
                            
                            // 2. Value and Details
                            VStack(alignment: .trailing, spacing: 1) {
                                Text(BRLFormatter.currency(row.quantity * row.unitPrice))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                
                                Text("\(BRLFormatter.quantity(row.quantity)) × \(BRLFormatter.decimal(row.unitPrice))")
                                    .font(.system(size: 10))
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                        .opacity(isDuplicate && skipDuplicates ? 0.5 : 1.0)
                    }
                }
            } header: {
                Text("Operações (\(preview.valid.count))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .textCase(nil)
            }
        }
        .listStyle(.plain)
        .background(DesignSystem.Colors.background)
        .scrollContentBackground(.hidden)
        .navigationTitle("Pré-visualização")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Voltar") { self.preview = nil }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Importar \(rowsToImport(preview).count)") {
                    confirmImport(preview)
                }
                .disabled(rowsToImport(preview).isEmpty)
            }
        }
    }

    // MARK: - Actions

    private func rowsToImport(_ preview: ImportPreview) -> [ParsedRow] {
        guard skipDuplicates, !preview.duplicates.isEmpty else { return preview.valid }
        let dupIDs = Set(preview.duplicates.map { $0.id })
        return preview.valid.filter { !dupIDs.contains($0.id) }
    }

    private func confirmImport(_ preview: ImportPreview) {
        do {
            try appState.importTransactions(rowsToImport(preview))
            isPresented = false
        } catch {
            parseError = error.localizedDescription
            self.preview = nil
        }
    }

    private func handlePickerResult(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                parseError = "Sem permissão para acessar o arquivo"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            let data = try Data(contentsOf: url)
            self.preview = try appState.previewImport(data: data)
            parseError = nil
        } catch {
            parseError = error.localizedDescription
            self.preview = nil
        }
    }
}
