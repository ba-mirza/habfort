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
                ProfilePanelView(email: email, viewModel: viewModel)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section("Ритм за 30 дней") {
                if let byDay = viewModel.discipline?.byDay, !byDay.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ActivityStrip(days: byDay)
                        Text("Высота столбика — доля выполненного за день.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } else {
                    Text("Пока нет данных за период.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Состав привычек") {
                if viewModel.habitCountsByType.isEmpty {
                    Text("Активных привычек нет.")
                        .foregroundStyle(.secondary)
                } else {
                    HabitCompositionBar(counts: viewModel.habitCountsByType)
                        .padding(.vertical, 6)
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
        .refreshable { await viewModel.load(apiClient: apiClient) }
        .task { await viewModel.load(apiClient: apiClient) }
    }
}
