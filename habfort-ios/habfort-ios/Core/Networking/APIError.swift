import Foundation

struct APIError: Error, LocalizedError {
    let status: Int
    let message: String

    var errorDescription: String? { message }
}

/// Nest's ValidationPipe sends `message` as a single string for most errors,
/// but as a string array for class-validator failures — decode either shape.
enum BackendErrorMessage: Decodable {
    case single(String)
    case multiple([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .single(value)
        } else {
            self = .multiple(try container.decode([String].self))
        }
    }

    var text: String {
        switch self {
        case .single(let value):
            return value
        case .multiple(let values):
            return values.joined(separator: ", ")
        }
    }
}

struct BackendErrorBody: Decodable {
    let statusCode: Int?
    let message: BackendErrorMessage?
    let error: String?
}
