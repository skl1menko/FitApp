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
    private var heartViewModel: HeartViewModel
    private var workoutViewModel: WorkoutViewModel
    private let healthKitManager = HealthKitManager.shared
    
    
    @Published var isAuthorized: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    init(stepsViewModel: StepsViewModel, caloriesViewModel: CaloriesViewModel, heartViewModel: HeartViewModel, workoutViewModel: WorkoutViewModel) {
        self.stepsViewModel = stepsViewModel
        self.caloriesViewModel = caloriesViewModel
        self.heartViewModel = heartViewModel
        self.workoutViewModel = workoutViewModel
    }
    
    func refresh(){
        stepsViewModel.loadSteps()
        caloriesViewModel.loadCalories()
        heartViewModel.loadHeartRate()
        workoutViewModel.loadWorkouts()
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
                    self?.heartViewModel.loadHeartRate()
                    self?.workoutViewModel.loadWorkouts()
                } else {
                    self?.errorMessage = "Не удалось получить разрешение на доступ к HealthKit"
                    self?.showError = true
                }
            }
        }
    }
    
    func loadData(for date: Date = Date()) {
        stepsViewModel.loadSteps(for:date)
        caloriesViewModel.loadCalories(for:date)
        heartViewModel.loadHeartRate(for:date)
        workoutViewModel.loadWorkouts(for:date)
    }
    
    func initialize() {
        requestHealthKitPermission()
    }
}
