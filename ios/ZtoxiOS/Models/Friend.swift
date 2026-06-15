import Foundation

struct Friend: Identifiable, Hashable {
    let id: UUID
    var publicKey: String   // 64 hex chars
    var name: String
    var statusMessage: String
    var status: Status

    enum Status: String {
        case online, away, busy, offline
    }
}

struct Message: Identifiable, Hashable {
    let id: UUID
    let authorIsSelf: Bool
    let body: String
    let sentAt: Date
}
