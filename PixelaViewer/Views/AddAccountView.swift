import SwiftUI

struct AddAccountView: View {
    @EnvironmentObject private var accountStore: AccountStore
    @Environment(\.dismiss) private var dismiss

    @State private var username = ""
    @State private var token = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section("アカウント情報") {
                    TextField("ユーザー名", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("ユーザートークン", text: $token)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("アカウントを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        addAccount()
                    }
                    .disabled(username.isEmpty || token.isEmpty || isLoading)
                }
            }
        }
    }

    private func addAccount() {
        isLoading = true
        errorMessage = nil
        do {
            try accountStore.addAccount(username: username, token: token)
            dismiss()
            Task { await accountStore.fetchAllGraphs() }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
