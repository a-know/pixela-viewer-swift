import Foundation
import Combine

@MainActor
final class AccountStore: ObservableObject {
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var graphs: [Graph] = []
    @Published private(set) var isLoading = false
    @Published var error: String?
    @Published private(set) var hasServerError = false
    @Published private(set) var hiddenGraphIDs: Set<String> = []
    @Published private(set) var pinnedGraphKeys: [String: Date] = [:]
    @Published var showHidden: Bool = false

    private let accountsKey = "saved_accounts"
    private let hiddenGraphIDsKey = "hidden_graph_ids"
    private let pinnedGraphKeysKey = "pinned_graph_keys"

    var visibleGraphs: [Graph] {
        let visible = graphs.filter { !isHidden($0) }
        let pinned = visible.filter { isPinned($0) }.sorted {
            (pinnedGraphKeys[graphKey($0)] ?? .distantFuture) < (pinnedGraphKeys[graphKey($1)] ?? .distantFuture)
        }
        let unpinned = visible.filter { !isPinned($0) }
        return pinned + unpinned
    }
    var hiddenGraphs: [Graph] { graphs.filter { isHidden($0) } }

    init() {
        loadAccounts()
        loadHiddenGraphIDs()
        loadPinnedGraphKeys()
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
        let removedKeys = graphs.filter { $0.account.id == account.id }.map { graphKey($0) }
        removedKeys.forEach {
            hiddenGraphIDs.remove($0)
            pinnedGraphKeys.removeValue(forKey: $0)
        }
        accounts.removeAll { $0.id == account.id }
        graphs.removeAll { $0.account.id == account.id }
        persistAccounts()
        persistHiddenGraphIDs()
        persistPinnedGraphKeys()
    }

    func isHidden(_ graph: Graph) -> Bool {
        hiddenGraphIDs.contains(graphKey(graph))
    }

    func hideGraph(_ graph: Graph) {
        hiddenGraphIDs.insert(graphKey(graph))
        persistHiddenGraphIDs()
    }

    func unhideGraph(_ graph: Graph) {
        hiddenGraphIDs.remove(graphKey(graph))
        persistHiddenGraphIDs()
    }

    func isPinned(_ graph: Graph) -> Bool {
        pinnedGraphKeys[graphKey(graph)] != nil
    }

    func pinGraph(_ graph: Graph) {
        pinnedGraphKeys[graphKey(graph)] = Date()
        persistPinnedGraphKeys()
    }

    func unpinGraph(_ graph: Graph) {
        pinnedGraphKeys.removeValue(forKey: graphKey(graph))
        persistPinnedGraphKeys()
    }

    private func graphKey(_ graph: Graph) -> String {
        "\(graph.account.username)/\(graph.graphID)"
    }

    func fetchAllGraphs() async {
        isLoading = true
        error = nil
        hasServerError = false
        var fetched: [Graph] = []
        for account in accounts {
            do {
                let token = try KeychainService.loadToken(for: account.username)
                let accountGraphs = try await PixelaAPIService.fetchGraphs(for: account, token: token)
                fetched.append(contentsOf: accountGraphs)
            } catch APIError.serverError(let code) {
                hasServerError = true
                self.error = "\(account.username): サーバーエラー (HTTP \(code))"
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

    private func persistHiddenGraphIDs() {
        UserDefaults.standard.set(Array(hiddenGraphIDs), forKey: hiddenGraphIDsKey)
    }

    private func loadHiddenGraphIDs() {
        let saved = UserDefaults.standard.stringArray(forKey: hiddenGraphIDsKey) ?? []
        hiddenGraphIDs = Set(saved)
    }

    private func persistPinnedGraphKeys() {
        let dict = pinnedGraphKeys.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(dict, forKey: pinnedGraphKeysKey)
    }

    private func loadPinnedGraphKeys() {
        guard let dict = UserDefaults.standard.dictionary(forKey: pinnedGraphKeysKey) as? [String: Double] else { return }
        pinnedGraphKeys = dict.mapValues { Date(timeIntervalSince1970: $0) }
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
