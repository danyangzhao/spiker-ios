import Foundation

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)
    case networkError(Error)

    /// User-friendly error description (hides technical details like status codes)
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Something went wrong. Please try again."
        case .invalidResponse:
            return "Received an unexpected response. Please try again."
        case .httpError(_, let message):
            return message
        case .decodingError:
            return "Something went wrong loading the data. Try again in a moment."
        case .networkError:
            return "Couldn't connect to the server. Check your internet and try again."
        }
    }

    /// Whether this error is a network/connectivity issue
    var isNetworkError: Bool {
        if case .networkError = self { return true }
        return false
    }
}

// MARK: - Error response from the API
struct APIErrorResponse: Codable {
    let error: String
    let details: String?
}

// MARK: - API Client
/// A simple HTTP client that talks to the Spikers API on Railway.
/// All methods are async and throw APIError on failure.
final class APIClient: Sendable {
    static let shared = APIClient()

    let baseURL: String

    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: String = "https://spikers-production.up.railway.app") {
        self.baseURL = baseURL
        self.session = URLSession.shared
        self.decoder = JSONDecoder()
    }

    // MARK: - Core request methods

    /// Perform a GET request and decode the response
    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        let url = try buildURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return try await perform(request)
    }

    /// Perform a POST request with a JSON body and decode the response
    func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        let url = try buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await perform(request)
    }

    /// Perform a PATCH request with a JSON body and decode the response
    func patch<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        let url = try buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await perform(request)
    }

    /// Perform a DELETE request and decode the response
    func delete<T: Decodable>(_ path: String) async throws -> T {
        let url = try buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        return try await perform(request)
    }

    /// Perform a DELETE request with no decoded response (just success/failure)
    func deleteVoid(_ path: String) async throws {
        let url = try buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let _: [String: Bool] = try await perform(request)
    }

    // MARK: - Private helpers

    private func buildURL(path: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        return url
    }

    private nonisolated func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Check for HTTP errors (4xx, 5xx)
        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message from response body
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError.httpError(
                    statusCode: httpResponse.statusCode,
                    message: errorResponse.error
                )
            }
            throw APIError.httpError(
                statusCode: httpResponse.statusCode,
                message: "Unknown error"
            )
        }

        // Decode the response
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
