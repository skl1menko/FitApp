//
//  AuthServise.swift
//  FitApp
//
//  Created by Sasha Klymenko on 27.01.2026.
//

import Foundation

class AuthService {
    static let shared = AuthService()
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    // Вход
    func login(email: String, password: String) async throws -> AuthData {
        let request = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await networkManager.request(
            endpoint: "/auth/login",
            method: .post,
            body: request
        )
        
        // Сохраняем токен
        networkManager.setAuthToken(response.data.token)
        
        return response.data
    }
    
    // Получение профиля
    func getProfile() async throws -> UserProfile {
        let response: ProfileResponse = try await networkManager.request(
            endpoint: "/auth/profile",
            method: .get,
            requiresAuth: true
        )
        
        return response.data
    }
    
    // Выход
    func logout() {
        networkManager.clearAuthToken()
    }
    
    // Проверка аутентификации
    func isAuthenticated() -> Bool {
        return networkManager.isAuthenticated()
    }
}
