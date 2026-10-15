import SwiftUI

/// A reward-diary card: the photo (if any), what was redeemed and when, and
/// the note. Tapping it opens the editor.
struct RedeemRowView: View {
    let redeem: Redeem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let url = redeem.photoUrl.flatMap(URL.init(string:)) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(.secondarySystemBackground).overlay(ProgressView())
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(redeem.rewardName)
                        .font(.headline)
                    Text(ISO8601.shortDate(from: redeem.redeemedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "seal.fill")
                    Text("−\(redeem.amountSpent)")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.secondary)
            }

            if let note = redeem.note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
            } else if redeem.photoUrl == nil {
                Label("Добавить фото и заметку", systemImage: "camera")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
