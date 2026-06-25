import Foundation
import MegrumCore

extension SupabaseAuthClient {
    func performAuthRequest(_ request: URLRequest) async throws -> AuthSession {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseAuthError.unexpectedStatus(-1, nil)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = try? decoder.decode(AuthErrorResponse.self, from: data).message
            throw SupabaseAuthError.unexpectedStatus(httpResponse.statusCode, message)
        }
        return try decoder.decode(AuthResponse.self, from: data).session
    }

    func performSignUpRequest(_ request: URLRequest) async throws -> AuthSession {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseAuthError.unexpectedStatus(-1, nil)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = try? decoder.decode(AuthErrorResponse.self, from: data).message
            throw SupabaseAuthError.unexpectedStatus(httpResponse.statusCode, message)
        }

        do {
            return try decoder.decode(AuthResponse.self, from: data).session
        } catch {
            if let pending = try? decoder.decode(SignUpPendingConfirmationResponse.self, from: data),
               pending.requiresEmailConfirmation {
                throw SupabaseAuthError.emailConfirmationRequired
            }
            throw error
        }
    }

    func makeAuthRequest(
        path: String,
        queryItems: [URLQueryItem] = [],
        method: String,
        body: Data?,
        bearerToken: String
    ) throws -> URLRequest {
        guard var components = URLComponents(url: configuration.projectURL, resolvingAgainstBaseURL: false) else {
            throw SupabaseAuthError.invalidURL
        }
        components.path = path.hasPrefix("/") ? path : "/\(path)"
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw SupabaseAuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
}
