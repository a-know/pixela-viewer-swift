import Foundation

enum PixelaAPIService {
    private static let baseURL = "https://pixe.la/v1/users"

    static func fetchGraphs(for account: Account, token: String) async throws -> [Graph] {
        guard let url = URL(string: "\(baseURL)/\(account.username)/graphs") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-USER-TOKEN")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.requestFailed
        }

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

    var errorDescription: String? {
        switch self {
        case .invalidURL: "URLの生成に失敗しました"
        case .requestFailed: "APIリクエストに失敗しました"
        }
    }
}
