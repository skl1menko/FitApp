//
//  SyncViewModel.swift
//  FitApp
//
//  Created by Sasha Klymenko on 27.01.2026.
//

import Foundation
import Combine

class SyncViewModel: ObservableObject {
    @Published var isSyncing = false
    @Published var syncMessage: String?
    @Published var showSuccess = false
    @Published var showError = false
    
    private let syncService = HealthSyncService.shared
    
    // Главная функция синхронизации
    func syncData(date: Date, steps: Double, calories: Double, heartRate: Double?) async {
        await MainActor.run {
            isSyncing = true
            syncMessage = "Синхронизация..."
        }
        
        do {
            // 1. Синхронизация общих дневных данных
            try await syncService.syncDayData(
                date: date,
                steps: steps,
                calories: calories,
                heartRate: heartRate
            )
            
            // 2. Синхронизация тренировок
            let workoutsCount = try await syncService.syncWorkouts(for: date)
            
            await MainActor.run {
                isSyncing = false
                syncMessage = "Успешно! Синхронизировано тренировок: \(workoutsCount)"
                showSuccess = true
            }
            
            // Скрыть сообщение через 3 секунды
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
}
