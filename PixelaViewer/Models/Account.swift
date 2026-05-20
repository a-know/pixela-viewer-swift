import Foundation

struct Account: Identifiable, Codable, Equatable {
    let id: UUID
    var username: String

    init(id: UUID = UUID(), username: String) {
        self.id = id
        self.username = username
    }
}
