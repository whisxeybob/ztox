import SwiftUI

@main
struct ZtoxApp: App {
    @StateObject private var tox = ToxRuntime()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(tox)
                .preferredColorScheme(.dark)
                .tint(Nord.frost10)
        }
    }
}
