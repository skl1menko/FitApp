//
//  CaloriesViewModel.swift
//  FitApp
//
//  Created by Sasha Klymenko on 26.12.2025.
//

import Foundation
import Combine

class CaloriesViewModel: ObservableObject {
    
    @Published var caloriesCount: Int = 0
    @Published var isLoading: Bool = false
    
    private let healthKitManager = HealthKitManager.shared
    private let caloriesService = CaloriesService()
    
    //Завантаження калорій
    func loadCalories(for date: Date = Date()) {
        isLoading = true
        caloriesService.getCalories(for: date) { [weak self] calories in
            DispatchQueue.main.async {
                self?.caloriesCount = Int(calories)
                self?.isLoading = false
            }
        }
    }
}
