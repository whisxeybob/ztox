import SwiftUI

struct ProfileSetupView: View {
    let onCreate: (String) -> Void
    @State private var name: String = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Nord.accentPrimary)
                Text("ztox")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Nord.textPrimary)
                Text("Privacy-first Tox messenger")
                    .font(.subheadline)
                    .foregroundStyle(Nord.textSecondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Username")
                    .font(.caption)
                    .foregroundStyle(Nord.textSecondary)
                TextField("e.g. anton", text: $name)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Nord.bgSecondary)
                    .foregroundStyle(Nord.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Nord.bgTertiary, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)

            Button {
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                onCreate(trimmed)
            } label: {
                Text("Create profile")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Nord.accentActive)
                    .foregroundStyle(Nord.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Spacer()

            Text("Your Tox profile is generated locally. No phone number, no email.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Nord.textMuted)
                .padding(.horizontal, 32)
        }
    }
}
