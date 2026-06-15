import SwiftUI

struct ContactListView: View {
    @EnvironmentObject var tox: ToxRuntime
    @State private var showAddFriend = false
    @State private var showProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                Nord.bgPrimary.ignoresSafeArea()
                Group {
                    if tox.contacts.isEmpty {
                        emptyState
                    } else {
                        contactList
                    }
                }
            }
            .navigationTitle("ztox")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showProfile = true } label: {
                        Image(systemName: "person.crop.circle")
                            .foregroundStyle(Nord.textPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddFriend = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Nord.textPrimary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text("ztox")
                            .font(.headline)
                            .foregroundStyle(Nord.textPrimary)
                        statusDot
                    }
                }
            }
        }
        .sheet(isPresented: $showAddFriend) { AddFriendSheet() }
        .sheet(isPresented: $showProfile) { ProfileSheet() }
    }

    private var statusDot: some View {
        Circle()
            .fill(connectionColor)
            .frame(width: 8, height: 8)
    }

    private var connectionColor: Color {
        switch tox.connection {
        case .online:     return Nord.statusOnline
        case .connecting: return Nord.statusAway
        case .offline:    return Nord.statusOffline
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Nord.textMuted)
            Text("No contacts yet")
                .font(.headline)
                .foregroundStyle(Nord.textPrimary)
            Text("Tap + to add someone by Tox ID.")
                .font(.subheadline)
                .foregroundStyle(Nord.textSecondary)
        }
    }

    private var contactList: some View {
        List(tox.contacts) { friend in
            NavigationLink(value: friend) {
                ContactRow(friend: friend)
            }
            .listRowBackground(Nord.bgPrimary)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationDestination(for: Friend.self) { friend in
            ChatView(friend: friend)
        }
    }
}

struct ContactRow: View {
    let friend: Friend

    var body: some View {
        HStack(spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Nord.textPrimary)
                Text(friend.statusMessage.isEmpty ? "Toxing on ztox" : friend.statusMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(Nord.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(Nord.bgTertiary)
            Text(String(friend.name.prefix(1)).uppercased())
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Nord.textPrimary)
        }
        .frame(width: 44, height: 44)
    }

    private var statusColor: Color {
        switch friend.status {
        case .online:  return Nord.statusOnline
        case .away:    return Nord.statusAway
        case .busy:    return Nord.statusBusy
        case .offline: return Nord.statusOffline
        }
    }
}
