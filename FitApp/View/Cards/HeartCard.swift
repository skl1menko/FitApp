//
//  HeartCard.swift
//  FitApp
//
//  Created by Sasha Klymenko on 26.12.2025.
//

import SwiftUI

struct HeartCard: View {
    let heartRate: Int
    let isLoading: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    . shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                if isLoading {
                    ProgressView()
                        . scaleEffect(1.2)
                } else {
                    VStack(spacing: geometry.size.height * 0.05) {
                        Text("❤️")
                            .font(.system(size: geometry.size.height * 0.25))
                        
                        Text("\(heartRate)")
                            .font(.system(size: geometry.size.height * 0.3, weight: .bold))
                            .foregroundColor(.primary)
                            .transition(.scale)
                            .minimumScaleFactor(0.5)
                        
                        Text("Heart Rate")
                            .font(.system(size: geometry.size.height * 0.12, weight: . medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .animation(.spring(), value: heartRate)
    }
}
