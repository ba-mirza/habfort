import SwiftUI

/// App settings, behind the gear on the profile: appearance, signing out and
/// deleting the account.
struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(APIClient.self) private var apiClient
    @State private var isConfirmingDeletion = false
    @State private var isDeleting = false
    @State private var deletionError: String?
    @State private var country: String?
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue

    private var theme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: appThemeRaw) ?? .system },
            set: { appThemeRaw = $0.rawValue }
        )
    }

    var body: some View {
        AppForm {
            Section("Аккаунт") {
                NavigationLink {
                    CountrySettingView(initial: country) { country = $0 }
                } label: {
                    LabeledContent("Страна") {
                        Text(country.flatMap(Country.named).map { "\($0.flag) \($0.name)" } ?? "Не выбрана")
                    }
                }
            }

            Section("Оформление") {
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
                .listRowInsets(EdgeInsets())
            }

            Section {
                Button(role: .destructive) {
                    isConfirmingDeletion = true
                } label: {
                    HStack {
                        Text("Удалить аккаунт")
                        Spacer()
                        if isDeleting { ProgressView() }
                    }
                }
                .disabled(isDeleting)
            } footer: {
                Text("Аккаунт и все данные — привычки, история, жетоны, награды и фото — будут удалены навсегда.")
            }
        }
        .confirmationDialog(
            "Удалить аккаунт навсегда?",
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button("Удалить аккаунт и все данные", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Это нельзя отменить. Жетоны, серия и уровень пропадут.")
        }
        .alert(
            "Не удалось удалить аккаунт",
            isPresented: Binding(get: { deletionError != nil }, set: { if !$0 { deletionError = nil } })
        ) {
            Button("Ок", role: .cancel) {}
        } message: {
            Text(deletionError ?? "")
        }
        .task {
            if let me: Me = try? await apiClient.get("/me") { country = me.country }
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await authManager.deleteAccount(apiClient: apiClient)
        } catch {
            deletionError = UserFacingError.message(for: error)
        }
    }
}
