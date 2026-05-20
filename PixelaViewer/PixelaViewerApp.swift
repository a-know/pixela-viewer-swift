import SwiftUI

@main
struct PixelaViewerApp: App {
    @StateObject private var accountStore = AccountStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(accountStore)
        }
    }
}
