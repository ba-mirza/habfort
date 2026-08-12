import Auth
import SwiftUI

struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(APIClient.self) private var apiClient
    @State private var viewModel = ProfileViewModel()
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue

    private var email: String {
        authManager.session?.user.email ?? "Аккаунт"
    }

    private var theme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: appThemeRaw) ?? .system },
            set: { appThemeRaw = $0.rawValue }
        )
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentColor)

                    Text(email)
                        .font(.headline)

                    HStack(spacing: 4) {
                        Image(systemName: "seal.fill")
                        Text("\(viewModel.walletBalance)")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowSeparator(.hidden)

            Section("Успешность привычек") {
                if let stats = viewModel.stats, stats.totalEntries > 0 {
                    HabitSuccessChartView(stats: stats)
                } else {
                    Text("Пока нет завершённых привычек.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Тема") {
                Picker("Тема", selection: theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Label(theme.displayName, systemImage: theme.iconName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Button(role: .destructive) {
                    Task { try? await authManager.signOut() }
                } label: {
                    Text("Выйти")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.red)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load(apiClient: apiClient) }
    }
}
