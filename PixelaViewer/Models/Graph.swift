import Foundation

struct Graph: Identifiable, Equatable {
    let id: String
    let account: Account
    let name: String
    let unit: String
    let type: String
    let color: String

    var graphID: String { id }

    func svgURL(isCompact: Bool, isDarkMode: Bool) -> URL? {
        var components = URLComponents(string: "https://pixe.la/v1/users/\(account.username)/graphs/\(graphID).svg")
        var queryItems: [URLQueryItem] = []
        if isCompact {
            queryItems.append(URLQueryItem(name: "mode", value: "short"))
        }
        if isDarkMode {
            queryItems.append(URLQueryItem(name: "appearance", value: "dark"))
            queryItems.append(URLQueryItem(name: "transparent", value: "true"))
        }
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }

    func htmlURL() -> URL? {
        URL(string: "https://pixe.la/v1/users/\(account.username)/graphs/\(graphID).html")
    }
}
