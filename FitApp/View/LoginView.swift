//
//  LoginView.swift
//  FitApp
//
//  Created by Sasha Klymenko on 27.01.2026.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Градиентный фон
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.6, blue: 1.0),
                        Color(red: 0.6, green: 0.4, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
                
                // Декоративные круги на фоне
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: geometry.size.width * 0.7)
                    .offset(x: -geometry.size.width * 0.3, y: -geometry.size.height * 0.3)
                
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: geometry.size.width * 0.4, y: geometry.size.height * 0.4)
                
                ScrollView {
                    VStack(spacing: 15) {
                        // Логотип и название (вверху)
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "figure.run.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            Text("FitApp")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        
                        Spacer()
                            .frame(height: 20)
                        
                        // Карточка с формой входа
                        VStack(spacing: 18) {
                            Text("Log in")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            // Поле Email
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Email", systemImage: "envelope.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 5)
                                
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.gray)
                                        .frame(width: 20)
                                    
                                    TextField("example@email.com", text: $email)
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Поле Пароль
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Password", systemImage: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 5)
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.gray)
                                        .frame(width: 20)
                                    
                                    SecureField("Enter password", text: $password)
                                        .textInputAutocapitalization(.never)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Сообщение об ошибке
                            if let errorMessage = authViewModel.errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text(errorMessage)
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Кнопка входа
                            Button(action: {
                                hideKeyboard()
                                Task {
                                    await authViewModel.login(email: email, password: password)
                                }
                            }) {
                                HStack {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Log in")
                                            .font(.headline)
                                        Image(systemName: "arrow.right")
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue,
                                            Color.blue.opacity(0.8)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                            }
                            .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
                            .opacity((authViewModel.isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                            .padding(.top, 5)
                        }
                        .padding(25)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal, max(20, geometry.size.width * 0.05))
                        
                        Spacer()
                            .frame(height: geometry.size.height * 0.15)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
            .onAppear {
                email = ""
                password = ""
                authViewModel.errorMessage = nil
                authViewModel.isLoading = false
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
