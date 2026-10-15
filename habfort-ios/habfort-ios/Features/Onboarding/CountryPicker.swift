import SwiftUI

/// Searchable country list with a one-tap "use my region" button.
struct CountryPicker: View {
    @Binding var selection: String?

    @State private var query = ""

    private var countries: [Country] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return Country.all }
        return Country.all.filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.code.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            ScrollViewReader { proxy in
                List(countries) { country in
                    Button {
                        selection = country.code
                    } label: {
                        HStack(spacing: 12) {
                            Text(country.flag).font(.title3)
                            Text(country.name).foregroundStyle(.primary)
                            Spacer()
                            if selection == country.code {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .id(country.code)
                    .listRowBackground(Color.secondary.opacity(0.08))
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .onAppear {
                    if let selection { proxy.scrollTo(selection, anchor: .center) }
                }
            }

            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Поиск", text: $query)
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                if let device = Country.deviceCountry {
                    Button {
                        selection = device.code
                        query = ""
                    } label: {
                        Label("Определить: \(device.flag) \(device.name)", systemImage: "location.fill")
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

/// Country choice outside onboarding: from Settings, or the one-time prompt
/// for accounts created before the country step existed.
struct CountrySettingView: View {
    let initial: String?
    var showsSkip = false
    let onSaved: (String) -> Void

    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss
    @State private var selection: String?
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(initial: String?, showsSkip: Bool = false, onSaved: @escaping (String) -> Void) {
        self.initial = initial
        self.showsSkip = showsSkip
        self.onSaved = onSaved
        _selection = State(initialValue: initial ?? Country.deviceCountry?.code)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Откуда вы?")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .padding(.top, 8)
            Text("Нужно для цен подписки и будущих функций в вашей стране.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            CountryPicker(selection: $selection)

            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }

            Button {
                Task { await save() }
            } label: {
                Group {
                    if isSaving { ProgressView() } else { Text("Сохранить") }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selection == nil || isSaving)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .toolbar {
            if showsSkip {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Позже") { dismiss() }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() async {
        guard let selection else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            let _: Me = try await apiClient.patch("/me", body: ["country": selection])
            onSaved(selection)
            dismiss()
        } catch {
            errorMessage = UserFacingError.message(for: error)
        }
    }
}
