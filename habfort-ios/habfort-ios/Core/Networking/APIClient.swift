import Foundation

@MainActor
@Observable
final class APIClient {
    private let baseURL: URL
    private let authManager: AuthManager
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(authManager: AuthManager, baseURL: URL = AppConfig.apiBaseURL, session: URLSession = .shared) {
        self.authManager = authManager
        self.baseURL = baseURL
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        let data = try await requestData(path: path, method: "GET", body: nil)
        return try decoder.decode(T.self, from: data)
    }

    func post<T: Decodable, Body: Encodable>(_ path: String, body: Body) async throws -> T {
        let data = try await requestData(path: path, method: "POST", body: try encoder.encode(body))
        return try decoder.decode(T.self, from: data)
    }

    func post<T: Decodable>(_ path: String) async throws -> T {
        let data = try await requestData(path: path, method: "POST", body: nil)
        return try decoder.decode(T.self, from: data)
    }

    func patch<T: Decodable, Body: Encodable>(_ path: String, body: Body) async throws -> T {
        let data = try await requestData(path: path, method: "PATCH", body: try encoder.encode(body))
        return try decoder.decode(T.self, from: data)
    }

    func patch<T: Decodable>(_ path: String) async throws -> T {
        let data = try await requestData(path: path, method: "PATCH", body: nil)
        return try decoder.decode(T.self, from: data)
    }

    func delete(_ path: String) async throws {
        _ = try await requestData(path: path, method: "DELETE", body: nil)
    }

    // Response shape for complete/log varies (Habit vs. HabitHistory depending
    // on whether the habit closed out), so these discard the body and let the
    // caller reload the habits list as the source of truth.
    func post(_ path: String) async throws {
        _ = try await requestData(path: path, method: "POST", body: nil)
    }

    func post<Body: Encodable>(_ path: String, body: Body) async throws {
        _ = try await requestData(path: path, method: "POST", body: try encoder.encode(body))
    }

    @discardableResult
    private func requestData(path: String, method: String, body: Data?) async throws -> Data {
        // `appendingPathComponent` would percent-escape a literal "?", breaking
        // any query string in `path` — build the URL via URLComponents instead
        // so callers can pass e.g. "/history?status=COMPLETED" directly.
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)!
        let parts = path.split(separator: "?", maxSplits: 1)
        components.path += parts[0]
        components.percentEncodedQuery = parts.count > 1 ? String(parts[1]) : nil
        guard let url = components.url else {
            throw APIError(status: 0, message: "Invalid request path")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authManager.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = body

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(status: 0, message: "Invalid response from server")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let errorBody = try? decoder.decode(BackendErrorBody.self, from: data), let message = errorBody.message {
                throw APIError(status: httpResponse.statusCode, message: message.text)
            }
            throw APIError(status: httpResponse.statusCode, message: "Request failed (\(httpResponse.statusCode))")
        }

        return data
    }
}
