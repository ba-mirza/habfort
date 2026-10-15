import SwiftUI

/// App settings, behind the gear on the profile: appearance and signing out.
struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue

    private var theme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: appThemeRaw) ?? .system },
            set: { appThemeRaw = $0.rawValue }
        )
    }

    var body: some View {
        AppForm {
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
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
    }
}
