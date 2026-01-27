//
//  FitAppApp.swift
//  FitApp
//
//  Created by Sasha Klymenko on 25.12.2025.
//

import SwiftUI

@main
struct FitAppApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                ContentView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
