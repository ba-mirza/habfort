import SwiftUI

/// Header for the History tab. The numbers are always all-time — the list
/// filters below don't narrow them, hence the explicit caption.
struct HistoryHeaderView: View {
    let stats: HistoryStats?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("За всё время")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))

            HStack(alignment: .firstTextBaseline, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(stats?.totalEntries ?? 0)")
                        .font(.largeTitle.bold())
                    Text("записей")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "seal.fill")
                        Text("\(stats?.totalCoinsAwarded ?? 0)")
                            .font(.title2.bold())
                    }
                    Text("жетонов заработано")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .foregroundStyle(.white)

            if let stats, !stats.byStatus.isEmpty {
                HStack(spacing: 6) {
                    ForEach(stats.byStatus) { row in
                        HStack(spacing: 4) {
                            Text(row.status.displayName)
                            Text("\(row.count)")
                                .fontWeight(.semibold)
                        }
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.25), in: Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
