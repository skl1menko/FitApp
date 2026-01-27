//
//  AuthModels.swift
//  FitApp
//
//  Created by Sasha Klymenko on 27.01.2026.
//

import Foundation

// Модели запросов
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

// Модели ответов
struct AuthResponse: Decodable {
    let status: String
    let data: AuthData
    let message: String?
}

struct AuthData: Decodable {
    let userId: Int
    let email: String
    let fullName: String
    let role: String
    let token: String
}

struct ProfileResponse: Decodable {
    let status: String
    let data: UserProfile
}

struct UserProfile: Decodable {
    let userId: Int
    let email: String
    let fullName: String
    let role: String
    let createdAt: String
}
