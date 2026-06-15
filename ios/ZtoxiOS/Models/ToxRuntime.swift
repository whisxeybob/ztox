import Foundation
import Combine

// Swift face of the c-toxcore runtime. Owns the Tox handle, the iterate
// timer, the contact list, and the connection state. SwiftUI views observe
// it via @EnvironmentObject.
//
// Once Frameworks/CToxcore.xcframework is in place (see scripts/
// build-toxcore-xcframework.sh), the .stub paths below get swapped for
// real `import CToxcore` calls. The shape of the @Published surface
// stays the same — UI code does not need to change.
@MainActor
final class ToxRuntime: ObservableObject {
    enum ConnectionState { case offline, connecting, online }
    enum Mode { case foreground }

    @Published var connection: ConnectionState = .offline
    @Published var selfName: String = "ztox"
    @Published var selfStatusMessage: String = "Toxing on ztox"
    @Published var selfToxId: String = ""
    @Published var contacts: [Friend] = []
    @Published var activeContact: Friend.ID?
    @Published var messages: [Friend.ID: [Message]] = [:]

    private var iterateTimer: Timer?
    private let mode: Mode = .foreground

    // MARK: - Lifecycle

    func bootstrap(profileName: String) async throws {
        // STUB: real implementation calls tox_options_new / tox_new with
        // savedata loaded from profile file in Application Support.
        // For the scaffold, we generate a placeholder Tox ID so the UI
        // has something to render.
        self.selfName = profileName
        self.selfToxId = Self.placeholderToxId()
        self.connection = .connecting
        startIterateLoop()
        // simulate DHT bootstrap success
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        self.connection = .online
    }

    func shutdown() {
        iterateTimer?.invalidate()
        iterateTimer = nil
        connection = .offline
    }

    // MARK: - Iteration

    private func startIterateLoop() {
        // tox_iterate() must be called every tox_iteration_interval() ms.
        // Stub loop: 50ms tick, drains nothing yet.
        iterateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.iterateTick() }
        }
    }

    private func iterateTick() {
        // Real impl: tox_iterate(handle, nil)
    }

    // MARK: - Friends

    func addFriend(toxId: String, message: String) throws {
        // Real impl: tox_friend_add(handle, addrBytes, msgBytes, len, &err)
        let friend = Friend(
            id: UUID(),
            publicKey: String(toxId.prefix(64)),
            name: "(unknown)",
            statusMessage: "",
            status: .offline
        )
        contacts.append(friend)
        messages[friend.id] = []
    }

    func send(_ text: String, to friendId: Friend.ID) {
        guard !text.isEmpty else { return }
        let msg = Message(id: UUID(), authorIsSelf: true, body: text, sentAt: Date())
        messages[friendId, default: []].append(msg)
        // Real impl: tox_friend_send_message(handle, friendNum, .normal, bytes, len, &err)
    }

    // MARK: - Helpers

    private static func placeholderToxId() -> String {
        // 76-char hex placeholder until tox_self_get_address provides the real one.
        var bytes = [UInt8](repeating: 0, count: 38)
        for i in 0..<38 { bytes[i] = UInt8.random(in: 0...255) }
        return bytes.map { String(format: "%02X", $0) }.joined()
    }
}
