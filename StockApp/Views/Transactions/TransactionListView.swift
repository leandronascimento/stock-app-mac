import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddTransaction = false
    @State private var transactionToEdit: Transaction?

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
                        }
                    }
                }
            }
            .navigationTitle("Operações")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
            .sheet(item: $transactionToEdit) { tx in
                AddTransactionView(transaction: tx)
            }
        }
    }
}
