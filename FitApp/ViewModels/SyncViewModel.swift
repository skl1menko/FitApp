//
//  SyncViewModel.swift
//  FitApp
//
//  Created by Sasha Klymenko on 27.01.2026.
//

import Foundation
import Combine
import HealthKit

class SyncViewModel: ObservableObject {
    // Состояние синхронизации метрик
    @Published var isSyncing = false
    @Published var syncMessage: String?
    @Published var showSuccess = false
    @Published var showError = false
    
    // Состояние бекенд-тренировок
    @Published var backendWorkouts: [BackendWorkout] = []
    @Published var isLoadingWorkouts = false
    @Published var syncingWorkoutId: Int? = nil
    @Published var syncedWorkoutIds: Set<Int> = []
    @Published var workoutSyncError: String? = nil
    
    private let syncService = HealthSyncService.shared
    
    // MARK: - Синхронизация только метрик (шаги, калории, пульс)
    func syncMetricsOnly(date: Date, steps: Double, calories: Double, heartRate: Double?) async {
        await MainActor.run {
            isSyncing = true
            syncMessage = "Синхронизация метрик..."
        }
        
        do {
            try await syncService.syncDayData(
                date: date,
                steps: steps,
                calories: calories,
                heartRate: heartRate
            )
            
            await MainActor.run {
                isSyncing = false
                syncMessage = "Метрики синхронизированы!"
                showSuccess = true
            }
            
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                showSuccess = false
                syncMessage = nil
            }
            
        } catch {
            await MainActor.run {
                isSyncing = false
                syncMessage = "Ошибка: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    // MARK: - Загрузить тренировки с бекенда
    func loadBackendWorkouts(for date: Date) async {
        await MainActor.run { isLoadingWorkouts = true }
        
        do {
            let workouts = try await syncService.getBackendWorkouts(for: date)
            print("📦 Загружено тренировок с бекенда: \(workouts.count)")
            await MainActor.run {
                backendWorkouts = workouts
                // Только сессионные синхронизации — не помечаем уже имеющиеся как "синхронизированные"
                isLoadingWorkouts = false
            }
        } catch {
            print("❌ Ошибка загрузки тренировок: \(error)")
            await MainActor.run {
                backendWorkouts = []
                isLoadingWorkouts = false
                workoutSyncError = "Ошибка загрузки: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Синхронизация с конкретно выбранным HKWorkout
    func syncWorkoutWithSelected(_ backendWorkout: BackendWorkout, hkWorkout: HKWorkout) async {
        await MainActor.run {
            syncingWorkoutId = backendWorkout.id
            workoutSyncError = nil
        }
        
        do {
            try await syncService.syncWorkoutWithHKWorkout(workoutId: backendWorkout.id, hkWorkout: hkWorkout)
            await MainActor.run {
                syncedWorkoutIds.insert(backendWorkout.id)
                syncingWorkoutId = nil
            }
        } catch {
            await MainActor.run {
                syncingWorkoutId = nil
                workoutSyncError = error.localizedDescription
            }
        }
    }
}
