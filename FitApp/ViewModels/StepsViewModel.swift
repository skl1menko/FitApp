//
//  StepsViewModel.swift
//  FitApp
//
//  Created by Sasha Klymenko on 25.12.2025.
//

import Foundation
import Combine

class StepsViewModel: ObservableObject {
    
    @Published var stepCount: Int = 0
    @Published var isLoading: Bool = false
    
    private let healthKitManager = HealthKitManager.shared
    private let stepsService = StepsService()
   
    // Загрузка шагов
    func loadSteps() {
        isLoading = true
        
        stepsService.getTodaySteps { [weak self] steps in
            DispatchQueue.main.async {
                self?.stepCount = Int(steps)
                self?.isLoading = false
            }
        }
    }
    
    
}
