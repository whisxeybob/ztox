import SwiftUI

struct ChatView: View {
    let friend: Friend
    @EnvironmentObject var tox: ToxRuntime
    @State private var draft: String = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            Nord.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                messagesList
                composer
            }
        }
        .navigationTitle(friend.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button { /* TODO: audio call */ } label: {
                        Image(systemName: "phone")
                            .foregroundStyle(Nord.statusOnline)
                    }
                    Button { /* TODO: video call */ } label: {
                        Image(systemName: "video")
                            .foregroundStyle(Nord.statusOnline)
                    }
                }
            }
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(tox.messages[friend.id] ?? []) { msg in
                        MessageBubble(message: msg).id(msg.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .onChange(of: tox.messages[friend.id]?.count) { _, _ in
                if let last = tox.messages[friend.id]?.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Type your message here…", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Nord.bgSecondary)
                .foregroundStyle(Nord.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(inputFocused ? Nord.accentPrimary : Nord.bgTertiary, lineWidth: 1)
                )
                .focused($inputFocused)
                .onSubmit(sendDraft)

            Button(action: sendDraft) {
                Image(systemName: "message.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Nord.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Nord.statusOnline)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Nord.bgPrimary)
    }

    private func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        tox.send(text, to: friend.id)
        draft = ""
    }
}

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.authorIsSelf { Spacer(minLength: 60) }
            Text(message.body)
                .font(.system(size: 15))
                .foregroundStyle(message.authorIsSelf ? Nord.textPrimary : Nord.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(message.authorIsSelf ? Nord.accentActive : Nord.bgSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            if !message.authorIsSelf { Spacer(minLength: 60) }
        }
    }
}
