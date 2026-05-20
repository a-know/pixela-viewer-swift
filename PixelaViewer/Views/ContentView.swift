import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var accountStore: AccountStore
    @State private var showAccountManagement = false

    var body: some View {
        NavigationStack {
            GraphListView()
                .navigationTitle("Pixela Viewer")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAccountManagement = true
                        } label: {
                            Image(systemName: "person.2")
                        }
                    }
                }
        }
        .sheet(isPresented: $showAccountManagement) {
            AccountManagementView()
        }
        .task {
            await accountStore.fetchAllGraphs()
        }
    }
}
