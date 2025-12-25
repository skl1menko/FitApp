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
    @Published var isAuthorized: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    private let healthKitManager = HealthKitManager.shared
    private let stepsService = StepsService()
    
    // Инициализация и запрос разрешений
    func initialize() {
        requestHealthKitPermission()
    }
    
    // Запрос разрешений HealthKit
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
                    self?.loadSteps()
                    self?.observeStepChanges()
                } else {
                    self?.errorMessage = "Не удалось получить разрешение на доступ к HealthKit"
                    self?.showError = true
                }
            }
        }
    }
    
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
    
    // Наблюдение за изменениями шагов
    private func observeStepChanges() {
        stepsService.observeStepCount { [weak self] in
            self?.loadSteps()
        }
    }
    
    // Обновление данных (для кнопки)
    func refresh() {
        loadSteps()
    }
}
