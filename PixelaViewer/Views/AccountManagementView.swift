import SwiftUI

struct AccountManagementView: View {
    @EnvironmentObject private var accountStore: AccountStore
    @Environment(\.dismiss) private var dismiss
    @State private var showAddAccount = false
    @State private var accountToDelete: Account?

    var body: some View {
        NavigationStack {
            List {
                ForEach(accountStore.accounts) { account in
                    Text(account.username)
                }
                .onDelete { indexSet in
                    if let index = indexSet.first {
                        accountToDelete = accountStore.accounts[index]
                    }
                }
            }
            .navigationTitle("アカウント管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        EditButton()
                        Button {
                            showAddAccount = true
                        } label: {
                            Image(systemName: "plus")
                        }
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
        .confirmationDialog(
            "\(accountToDelete?.username ?? "") を削除しますか？",
            isPresented: Binding(
                get: { accountToDelete != nil },
                set: { if !$0 { accountToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                if let account = accountToDelete {
                    accountStore.removeAccount(account)
                }
                accountToDelete = nil
            }
            Button("キャンセル", role: .cancel) {
                accountToDelete = nil
            }
        } message: {
            Text("このアカウントとそのグラフ情報がアプリから削除されます。")
        }
    }
}
