import SwiftUI

struct RootView: View {
    @EnvironmentObject var tox: ToxRuntime
    @AppStorage("profileBootstrapped") private var profileBootstrapped = false

    var body: some View {
        ZStack {
            Nord.bgPrimary.ignoresSafeArea()
            if profileBootstrapped {
                ContactListView()
            } else {
                ProfileSetupView(onCreate: { name in
                    Task {
                        try? await tox.bootstrap(profileName: name)
                        profileBootstrapped = true
                    }
                })
            }
        }
    }
}
