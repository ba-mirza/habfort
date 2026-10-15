import SwiftUI

/// Privacy policy and terms, bundled so they open without a network or a
/// website. The same text needs a public URL for App Store Connect.
enum LegalDocument: String, Identifiable {
    case privacy, terms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacy: "Политика конфиденциальности"
        case .terms: "Условия использования"
        }
    }

    var sections: [(heading: String, body: String)] {
        switch self {
        case .privacy:
            [
                ("Какие данные мы храним", "Email и идентификатор аккаунта (при входе через Apple — только то, чем Apple разрешила поделиться). Привычки, их выполнение, жетоны, награды, заметки и фото дневника наград, которые вы добавляете сами."),
                ("Зачем", "Только чтобы приложение работало: считать жетоны, серии, уровни и статистику и показывать их вам. Мы не продаём данные, не показываем рекламу и не используем трекинг."),
                ("Где хранятся", "На серверах Supabase (база данных, вход и хранилище фото) и нашего API. Фото лежат в закрытом хранилище и доступны только вам по временным ссылкам."),
                ("Уведомления", "Напоминания создаются на самом устройстве. Мы не отправляем push-уведомления с сервера."),
                ("Удаление", "Аккаунт и все данные, включая фото, удаляются навсегда в Профиль → Настройки → «Удалить аккаунт»."),
                ("Связь", "Вопросы о данных — через страницу приложения в App Store."),
            ]
        case .terms:
            [
                ("Сервис", "Beles — личный трекер привычек с жетонами. Жетоны не являются деньгами, не продаются, не выводятся и имеют смысл только внутри приложения."),
                ("Награды", "Награды вы назначаете и получаете сами в реальной жизни. Приложение лишь учитывает потраченные жетоны."),
                ("Аккаунт", "Вы отвечаете за доступ к своему аккаунту. Аккаунт можно удалить в любой момент в настройках."),
                ("Изменения", "Сервис развивается: функции и правила начисления жетонов могут меняться. О существенных изменениях мы сообщим в приложении."),
                ("Ответственность", "Приложение предоставляется «как есть». Мы стараемся, чтобы оно работало стабильно, но не гарантируем отсутствие сбоев."),
            ]
        }
    }
}

struct LegalDocumentView: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(document.sections, id: \.heading) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.heading).font(.headline)
                            Text(section.body).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}
