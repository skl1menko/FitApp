//
//  RefreshButton.swift
//  FitApp
//
//  Created by Sasha Klymenko on 26.12.2025.
//
import SwiftUI
// MARK: - Компонент кнопки обновления
struct RefreshButton: View {
    let action: () -> Void
    
    var body:  some View {
        Button(action: action) {
            HStack {
                Image(systemName:  "arrow.clockwise")
                Text("Обновить")
            }
            .font(. system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 200, height: 50)
            .background(Color.blue)
            .cornerRadius(15)
        }
    }
}

