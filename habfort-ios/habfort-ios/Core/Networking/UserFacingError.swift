import AuthenticationServices
import Foundation

/// Turns any error into a short Russian sentence fit for the user. Raw system
/// and server texts ("com.apple.AuthenticationServices…, ошибка 1000",
/// English validation messages) never reach the screen: known cases get a
/// specific message, everything else a neutral one.
enum UserFacingError {
    static let generic = "Что-то пошло не так. Попробуйте ещё раз."

    /// Nil when the error needs no message at all (the user cancelled).
    static func message(for error: Error) -> String {
        optionalMessage(for: error) ?? generic
    }

    static func isCancellation(_ error: Error) -> Bool {
        if let error = error as? ASAuthorizationError, error.code == .canceled { return true }
        if error is CancellationError { return true }
        if let error = error as? URLError, error.code == .cancelled { return true }
        return false
    }

    private static func optionalMessage(for error: Error) -> String? {
        if let error = error as? URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return "Нет соединения с интернетом."
            case .timedOut, .cannotConnectToHost, .cannotFindHost:
                return "Сервер не отвечает. Попробуйте позже."
            default:
                return nil
            }
        }

        if error is ASAuthorizationError {
            return "Не удалось войти через Apple. Проверьте, что на устройстве выполнен вход в Apple ID."
        }

        if let error = error as? APIError {
            return apiMessage(error)
        }

        return authMessage(error.localizedDescription.lowercased())
    }

    private static func apiMessage(_ error: APIError) -> String? {
        // Status 0 marks errors the app builds itself — already in Russian.
        if error.status == 0 { return error.message }

        let text = error.message.lowercased()
        switch error.status {
        case 401: return "Сессия истекла. Войдите снова."
        case 404: return "Не нашли это — обновите экран."
        case 429: return "Слишком много запросов. Подождите немного."
        case 500...: return "Сервер временно недоступен. Попробуйте позже."
        default: break
        }
        if text.contains("insufficient coins") { return "Не хватает жетонов на эту награду." }
        if text.contains("reward cost must be at least"),
           let minimum = text.split(separator: " ").compactMap({ Int($0) }).first {
            return "Цена награды — минимум \(minimum) жетонов."
        }
        if text.contains("archived") { return "Эта награда в архиве." }
        if text.contains("only today") { return "Отмечать можно только сегодня." }
        if text.contains("not scheduled") { return "Эта привычка не запланирована на сегодня." }
        if text.contains("difficulty of a conditional") { return "Сложность челленджа менять нельзя." }
        return nil
    }

    /// Supabase Auth answers in English.
    private static func authMessage(_ text: String) -> String? {
        if text.contains("invalid login credentials") { return "Неверный email или пароль." }
        if text.contains("already registered") || text.contains("already been registered") {
            return "Этот email уже зарегистрирован — попробуйте войти."
        }
        if text.contains("password should be") || text.contains("weak password") {
            return "Пароль слишком простой — минимум 6 символов."
        }
        if text.contains("rate limit") || text.contains("for security purposes") {
            return "Слишком много попыток. Подождите минуту."
        }
        if text.contains("email") && (text.contains("invalid") || text.contains("valid email")) {
            return "Проверьте адрес email."
        }
        return nil
    }
}
