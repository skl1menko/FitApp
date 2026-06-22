//
//  AuthViewModel.swift
//  FitApp
//
//  Created by Sasha Klymenko on 27.01.2026.
//

import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: AuthData?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let authService = AuthService.shared
    
    init() {
        checkAuthentication()
    }
    
    func checkAuthentication() {
        isAuthenticated = authService.isAuthenticated()
    }
    
    // Login
    func login(email: String, password: String) async {
        await MainActor.run { isLoading = true }
        
        do {
            let userData = try await authService.login(email: email, password: password)
            await MainActor.run {
                self.currentUser = userData
                self.isAuthenticated = true
                self.isLoading = false
                self.errorMessage = nil
            }
        } catch NetworkError.serverError(let message) {
            await MainActor.run {
                self.errorMessage = message
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Invalid email or password"
                self.isLoading = false
            }
        }
    }
    
    // Load profile
    func loadProfile() async {
        do {
            let profile = try await authService.getProfile()
            await MainActor.run {
                // Update user data
                print("Profile loaded: \(profile.fullName)")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load profile"
            }
        }
    }
    
    // Выход
    func logout() {
        Task { @MainActor in
            authService.logout()
            currentUser = nil
            isAuthenticated = false
        }
    }
}
