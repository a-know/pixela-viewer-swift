import Foundation

enum PixelaAPIService {
    private static let baseURL = "https://pixe.la/v1/users"

    static func authenticate(username: String, token: String) async throws {
        guard let url = URL(string: "\(baseURL)/\(username)/authentication") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "X-USER-TOKEN")

        let (data, response) = try await URLSession.shared.data(for: request)
        let body = try? JSONDecoder().decode(PixelaResponse.self, from: data)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200, body?.isSuccess == true else {
            throw APIError.authenticationFailed(body?.message ?? "認証に失敗しました")
        }
    }

    static func fetchGraphStats(for graph: Graph, token: String) async throws -> GraphStats {
        guard let url = URL(string: "\(baseURL)/\(graph.account.username)/graphs/\(graph.graphID)/stats") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-USER-TOKEN")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.requestFailed }
        if (500...599).contains(http.statusCode) { throw APIError.serverError(http.statusCode) }
        guard http.statusCode == 200 else { throw APIError.requestFailed }

        return try JSONDecoder().decode(GraphStats.self, from: data)
    }

    static func fetchGraphs(for account: Account, token: String) async throws -> [Graph] {
        guard let url = URL(string: "\(baseURL)/\(account.username)/graphs") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-USER-TOKEN")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.requestFailed }
        if (500...599).contains(http.statusCode) { throw APIError.serverError(http.statusCode) }
        guard http.statusCode == 200 else { throw APIError.requestFailed }

        let decoded = try JSONDecoder().decode(GraphListResponse.self, from: data)
        return decoded.graphs.map { dto in
            Graph(
                id: dto.id,
                account: account,
                name: dto.name,
                unit: dto.unit,
                type: dto.type,
                color: dto.color
            )
        }
    }
}

private struct PixelaResponse: Decodable {
    let message: String
    let isSuccess: Bool
}

private struct GraphListResponse: Decodable {
    let graphs: [GraphDTO]
}

private struct GraphDTO: Decodable {
    let id: String
    let name: String
    let unit: String
    let type: String
    let color: String
}

enum APIError: LocalizedError {
    case invalidURL
    case requestFailed
    case serverError(Int)
    case authenticationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "URLの生成に失敗しました"
        case .requestFailed: "APIリクエストに失敗しました"
        case .serverError(let code): "サーバーエラーが発生しました (HTTP \(code))"
        case .authenticationFailed(let message): message
        }
    }
}
