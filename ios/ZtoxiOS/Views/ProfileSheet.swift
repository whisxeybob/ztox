import SwiftUI

struct ProfileSheet: View {
    @EnvironmentObject var tox: ToxRuntime
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Nord.bgPrimary.ignoresSafeArea()
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text(tox.selfName)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Nord.textPrimary)
                        Text(tox.selfStatusMessage)
                            .font(.subheadline)
                            .foregroundStyle(Nord.textSecondary)
                    }
                    .padding(.top, 24)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Tox ID")
                            .font(.caption)
                            .foregroundStyle(Nord.textSecondary)
                        Text(tox.selfToxId)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(Nord.textPrimary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Nord.bgSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, 20)

                    Button {
                        UIPasteboard.general.string = tox.selfToxId
                    } label: {
                        Label("Copy Tox ID", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Nord.bgTertiary)
                            .foregroundStyle(Nord.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Nord.accentPrimary)
                }
            }
        }
    }
}
