//
//  WorkoutSyncViewModel.swift
//  FitApp
//
//  Created by Sasha Klymenko on 27.03.2026.
//

import Foundation
import HealthKit
import Combine

@MainActor
class WorkoutSyncViewModel: ObservableObject {
    @Published var appleHealthWorkouts: [AppleHealthWorkout] = []
    @Published var backendWorkouts: [BackendWorkout] = []
    @Published var selectedAppleWorkout: AppleHealthWorkout?
    @Published var selectedBackendWorkout: BackendWorkout?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var selectedDate = Date()
    
    private let healthSyncService = HealthSyncService.shared
    
    // Загрузить тренировки за выбранную дату
    func loadWorkouts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Загружаем тренировки из обоих источников
            async let appleWorkouts = loadAppleHealthWorkouts()
            async let backendWorkoutsList = loadBackendWorkouts()
            
            let (apple, backend) = try await (appleWorkouts, backendWorkoutsList)
            
            appleHealthWorkouts = apple
            backendWorkouts = backend
            
        } catch {
            errorMessage = "Loading error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func loadAppleHealthWorkouts() async throws -> [AppleHealthWorkout] {
        let hkWorkouts = try await healthSyncService.getHealthKitWorkouts(for: selectedDate)
        return hkWorkouts.map { AppleHealthWorkout(hkWorkout: $0) }
            .sorted { $0.startDate > $1.startDate } // Новые сначала
    }
    
    private func loadBackendWorkouts() async throws -> [BackendWorkout] {
        let workouts = try await healthSyncService.getBackendWorkouts(for: selectedDate)
        return workouts.sorted { workout1, workout2 in
            guard let date1 = workout1.workoutDateTime,
                  let date2 = workout2.workoutDateTime else {
                return false
            }
            return date1 > date2 // Новые сначала
        }
    }
    
    // Синхронизировать выбранные тренировки
    func syncSelectedWorkouts() async {
        guard let appleWorkout = selectedAppleWorkout,
              let backendWorkout = selectedBackendWorkout else {
            errorMessage = "Select both workouts to sync"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await healthSyncService.syncWorkoutWithHKWorkout(
                workoutId: backendWorkout.workoutId,
                hkWorkout: appleWorkout.hkWorkout
            )
            
            successMessage = "Workout successfully synchronized!"
            
            // Clear selection
            selectedAppleWorkout = nil
            selectedBackendWorkout = nil
            
            // Refresh backend workouts
            await loadWorkouts()
            
        } catch {
            errorMessage = "Synchronization error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Проверить, можно ли синхронизировать
    var canSync: Bool {
        selectedAppleWorkout != nil && selectedBackendWorkout != nil && !isLoading
    }
}
