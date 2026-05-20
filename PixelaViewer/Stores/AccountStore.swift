import Foundation
import Combine

@MainActor
final class AccountStore: ObservableObject {
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var graphs: [Graph] = []
    @Published private(set) var isLoading = false
    @Published var error: String?

    private let accountsKey = "saved_accounts"

    init() {
        loadAccounts()
    }

    func addAccount(username: String, token: String) async throws {
        guard !accounts.contains(where: { $0.username == username }) else {
            throw AccountError.duplicateUsername
        }
        try await PixelaAPIService.authenticate(username: username, token: token)
        try KeychainService.saveToken(token, for: username)
        let account = Account(username: username)
        accounts.append(account)
        persistAccounts()
    }

    func removeAccount(_ account: Account) {
        KeychainService.deleteToken(for: account.username)
        accounts.removeAll { $0.id == account.id }
        graphs.removeAll { $0.account.id == account.id }
        persistAccounts()
    }

    func fetchAllGraphs() async {
        isLoading = true
        error = nil
        var fetched: [Graph] = []
        for account in accounts {
            do {
                let token = try KeychainService.loadToken(for: account.username)
                let accountGraphs = try await PixelaAPIService.fetchGraphs(for: account, token: token)
                fetched.append(contentsOf: accountGraphs)
            } catch {
                self.error = "\(account.username): \(error.localizedDescription)"
            }
        }
        graphs = fetched
        isLoading = false
    }

    private func persistAccounts() {
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        UserDefaults.standard.set(data, forKey: accountsKey)
    }

    private func loadAccounts() {
        guard let data = UserDefaults.standard.data(forKey: accountsKey),
              let saved = try? JSONDecoder().decode([Account].self, from: data) else { return }
        accounts = saved
    }
}

enum AccountError: LocalizedError {
    case duplicateUsername

    var errorDescription: String? {
        switch self {
        case .duplicateUsername: "同じユーザー名のアカウントがすでに登録されています"
        }
    }
}
