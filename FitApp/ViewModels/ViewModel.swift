//
//  ViewModel.swift
//  FitApp
//
//  Created by Sasha Klymenko on 26.12.2025.
//

import Foundation
import Combine
import HealthKit



class ViewModel: ObservableObject {
    
    private var stepsViewModel: StepsViewModel
    private var caloriesViewModel: CaloriesViewModel
    private let healthKitManager = HealthKitManager.shared
    private let stepsService = StepsService()
    @Published var isAuthorized: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    init(stepsViewModel: StepsViewModel, caloriesViewModel: CaloriesViewModel) {
        self.stepsViewModel = stepsViewModel
        self.caloriesViewModel = caloriesViewModel
    }
    
    func refresh(){
        stepsViewModel.loadSteps()
        caloriesViewModel.loadCalories()
    }
    
    private func requestHealthKitPermission() {
        guard healthKitManager.isHealthKitAvailable() else {
            errorMessage = "HealthKit недоступен на этом устройстве"
            showError = true
            return
        }
        
        healthKitManager.requestAuthorization { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.stepsViewModel.loadSteps()
                    self?.caloriesViewModel.loadCalories()
                } else {
                    self?.errorMessage = "Не удалось получить разрешение на доступ к HealthKit"
                    self?.showError = true
                }
            }
        }
    }
    
    func initialize() {
        requestHealthKitPermission()
    }
}
