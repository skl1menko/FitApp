//
//  HeartViewModel.swift
//  FitApp
//
//  Created by Sasha Klymenko on 26.12.2025.
//
import Foundation
import Combine

class HeartViewModel: ObservableObject {
    @Published var heartRate: Int = 0
    @Published var isLoading: Bool = false
    
    private let healthKitManager = HealthKitManager.shared
    private let heartService = HeartrateService()
    
    func loadHeartRate(for date: Date = Date()) {
        isLoading = true
        
        heartService.getHeartrate(for: date){ [weak self] heartRate in
            DispatchQueue.main.async {
                self?.heartRate = Int(heartRate)
                self?.isLoading = false
                
            }
            
        }
    }
}
