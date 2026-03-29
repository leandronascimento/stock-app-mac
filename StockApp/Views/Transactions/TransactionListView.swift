import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddTransaction = false
    @State private var transactionToEdit: Transaction?
    @State private var showingImport = false

    var body: some View {
        NavigationStack {
            Group {
                if appState.transactions.isEmpty {
                    ContentUnavailableView(
                        "Nenhuma operação",
                        systemImage: "tray",
                        description: Text("Toque em + para adicionar sua primeira operação")
                    )
                } else {
                    List {
                        ForEach(appState.transactions.reversed()) { tx in
                            TransactionRowView(transaction: tx)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    transactionToEdit = tx
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        try? appState.delete(id: tx.id)
                                    } label: {
                                        Label("Excluir", systemImage: "trash")
                                    }
                                }
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .background(DesignSystem.Colors.background)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Operações")
            .toolbarBackground(DesignSystem.Colors.background)
            .toolbarBackground(.visible)
            .background(DesignSystem.Colors.background)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showingImport = true
                    } label: {
                        Label("Importar CSV", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
            .sheet(item: $transactionToEdit) { tx in
                AddTransactionView(transaction: tx)
            }
            .sheet(isPresented: $showingImport) {
                CSVImportView(isPresented: $showingImport)
            }
        }
    }
}
