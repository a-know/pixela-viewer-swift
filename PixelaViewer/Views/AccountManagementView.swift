import SwiftUI

struct AccountManagementView: View {
    @EnvironmentObject private var accountStore: AccountStore
    @Environment(\.dismiss) private var dismiss
    @State private var showAddAccount = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(accountStore.accounts) { account in
                    Text(account.username)
                }
                .onDelete { indexSet in
                    indexSet.forEach { accountStore.removeAccount(accountStore.accounts[$0]) }
                }
            }
            .navigationTitle("アカウント管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddAccount = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .overlay {
                if accountStore.accounts.isEmpty {
                    ContentUnavailableView(
                        "アカウントがありません",
                        systemImage: "person.slash",
                        description: Text("＋ボタンから追加してください")
                    )
                }
            }
        }
        .sheet(isPresented: $showAddAccount) {
            AddAccountView()
        }
    }
}
