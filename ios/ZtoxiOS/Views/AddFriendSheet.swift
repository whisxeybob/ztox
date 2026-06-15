import SwiftUI

struct AddFriendSheet: View {
    @EnvironmentObject var tox: ToxRuntime
    @Environment(\.dismiss) var dismiss

    @State private var toxId = ""
    @State private var message = "Hi from ztox"

    var body: some View {
        NavigationStack {
            ZStack {
                Nord.bgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        labeledField(
                            title: "Tox ID",
                            placeholder: "76 hex chars",
                            text: $toxId,
                            monospaced: true
                        )
                        labeledField(
                            title: "Greeting",
                            placeholder: "Sent with the friend request",
                            text: $message,
                            monospaced: false
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Nord.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Send") {
                        try? tox.addFriend(toxId: toxId, message: message)
                        dismiss()
                    }
                    .disabled(toxId.count != 76)
                    .foregroundStyle(toxId.count == 76 ? Nord.accentPrimary : Nord.textMuted)
                }
            }
        }
    }

    private func labeledField(title: String, placeholder: String, text: Binding<String>, monospaced: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Nord.textSecondary)
            TextField(placeholder, text: text, axis: .vertical)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .lineLimit(monospaced ? 4 : 2, reservesSpace: true)
                .padding(12)
                .background(Nord.bgSecondary)
                .foregroundStyle(Nord.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
