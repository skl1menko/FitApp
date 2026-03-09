import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
}

class NetworkManager {
    static let shared = NetworkManager()
    
    // ЗАМЕНИТЕ НА ВАШ NGROK URL
    // Например: "https://fatimah-unfrequentable-colby.ngrok-free.dev"
    private let baseURL = "https://fatimah-unfrequentable-colby.ngrok-free.dev"
    
    private var authToken: String? {
        get { UserDefaults.standard.string(forKey: "authToken") }
        set { UserDefaults.standard.set(newValue, forKey: "authToken") }
    }
    
    private init() {}
    
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = false
    ) async throws -> T {
        let fullURL = baseURL + "/api" + endpoint
        
        guard let url = URL(string: fullURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // ngrok может требовать этот header для обхода предупреждений
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        if requiresAuth, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            // Убрали .iso8601 чтобы использовать кастомную кодировку дат
            request.httpBody = try encoder.encode(body)
            
            #if DEBUG
            if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                print("📤 JSON Body: \(jsonString)")
            }
            #endif
        }
        
        #if DEBUG
        print("📡 Request: \(method.rawValue) \(fullURL)")
        if let body = body {
            print("📦 Body: \(body)")
        }
        #endif
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }
        
        #if DEBUG
        print("📥 Response Status: \(httpResponse.statusCode)")
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 Response Data: \(jsonString)")
        }
        #endif
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }
            
            // Попытка получить сообщение об ошибке от сервера
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorResponse.message ?? "Status code: \(httpResponse.statusCode)")
            }
            
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("❌ Decoding error: \(error)")
            #endif
            throw NetworkError.decodingError
        }
    }
    
    func setAuthToken(_ token: String) {
        authToken = token
    }
    
    func clearAuthToken() {
        authToken = nil
    }
    
    func isAuthenticated() -> Bool {
        return authToken != nil
    }
}

// Модель для ошибок от сервера
struct ErrorResponse: Decodable {
    let status: String?
    let message: String?
}
