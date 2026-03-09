//
//  HealthSyncService.swift
//  FitApp
//
//  Created by Sasha Klymenko on 27.01.2026.
//

import Foundation
import HealthKit

class HealthSyncService {
    static let shared = HealthSyncService()
    private let networkManager = NetworkManager.shared
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    // MARK: - Основная синхронизация за день
    func syncDayData(date: Date, steps: Double, calories: Double, heartRate: Double?) async throws {
        let startOfDay = Calendar.current.startOfDay(for: date)
        
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)!
        
        let request = SyncHealthMetricsRequest(
            workoutId: nil,
            periodType: "daily",
            startDate: startOfDay,
            endDate: endOfDay,
            stepCount: steps > 0 ? Int(steps) : nil,
            totalEnergyBurned: calories > 0 ? calories : nil,
            avgHeartRate: heartRate.map { Int(round($0)) },
            sourceName: "Apple Health"
        )
        
        let _: SyncResponse = try await networkManager.request(
            endpoint: "/health-metrics/ios",
            method: .post,
            body: request,
            requiresAuth: true
        )
        
        print("✅ Синхронизированы дневные данные за \(date)")
    }
    
    // MARK: - Получить тренировки из backend за день
    func getBackendWorkouts(for date: Date) async throws -> [BackendWorkout] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let formatter = ISO8601DateFormatter()
        let startStr = formatter.string(from: startOfDay)
        let endStr = formatter.string(from: endOfDay)
        
        let response: WorkoutsResponse = try await networkManager.request(
            endpoint: "/workouts/range?start=\(startStr)&end=\(endStr)",
            method: .get,
            requiresAuth: true
        )
        
        return response.data
    }
    
    // MARK: - Получить тренировки из HealthKit за день
    func getHealthKitWorkouts(for date: Date) async throws -> [HKWorkout] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Сопоставить тренировки и синхронизировать
    func syncWorkouts(for date: Date) async throws -> Int {
        // 1. Получить тренировки из backend
        let backendWorkouts = try await getBackendWorkouts(for: date)
        print("📊 Backend тренировок: \(backendWorkouts.count)")
        
        // 2. Получить тренировки из HealthKit
        let healthKitWorkouts = try await getHealthKitWorkouts(for: date)
        print("📊 HealthKit тренировок: \(healthKitWorkouts.count)")
        
        var syncedCount = 0
        
        // 3. Для каждой тренировки из backend найти соответствующую в HealthKit
        for backendWorkout in backendWorkouts {
            guard let backendDate = backendWorkout.workoutDateTime else {
                print("⚠️ Backend тренування #\(backendWorkout.id) - не вдалося розпарсити дату")
                continue
            }
            
            print("🔍 Шукаємо пару для тренування #\(backendWorkout.id) (backend: \(backendDate))")
            
            // Найти тренировку в HealthKit по времени (в пределах ±30 минут)
            let matchedWorkout = healthKitWorkouts.first { hkWorkout in
                let timeDifference = abs(hkWorkout.startDate.timeIntervalSince(backendDate))
                print("   ⏱ HealthKit: \(hkWorkout.startDate), різниця: \(Int(timeDifference))s")
                return timeDifference < 1800 // 30 минут
            }
            
            if let hkWorkout = matchedWorkout {
                print("✅ Знайдено пару! Синхронізуємо тренування #\(backendWorkout.id)")
                // Синхронизировать метрики тренировки
                try await syncWorkoutMetrics(
                    workoutId: backendWorkout.id,
                    hkWorkout: hkWorkout
                )
                syncedCount += 1
            } else {
                print("❌ Пара не знайдена для тренування #\(backendWorkout.id)")
            }
        }
        
        print("📈 Всього синхронізовано: \(syncedCount) з \(backendWorkouts.count)")
        return syncedCount
    }
    
    // MARK: - Синхронизация метрик конкретной тренировки
    private func syncWorkoutMetrics(workoutId: Int, hkWorkout: HKWorkout) async throws {
        // Перевірити чи метрики вже існують
        do {
            struct WorkoutMetricsResponse: Decodable {
                let status: String
                let data: [HealthMetric]
                
                struct HealthMetric: Decodable {
                    let metricId: Int
                }
            }
            
            let response: WorkoutMetricsResponse = try await networkManager.request(
                endpoint: "/health-metrics/workout/\(workoutId)",
                method: .get,
                requiresAuth: true
            )
            
            // Якщо є метрики - пропускаємо
            if !response.data.isEmpty {
                print("⚠️ Метрики для тренування #\(workoutId) вже існують, пропускаємо")
                return
            }
        } catch {
            // Помилка або метрик немає - продовжуємо
        }
        
        // Получить данные из HealthKit для этой тренировки
        let calories = hkWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
        let heartRate = try? await getAverageHeartRate(for: hkWorkout)
        
        let request = SyncHealthMetricsRequest(
            workoutId: workoutId,
            periodType: "workout",
            startDate: hkWorkout.startDate,
            endDate: hkWorkout.endDate,
            stepCount: nil, // для тренировки обычно не нужны шаги
            totalEnergyBurned: calories,
            avgHeartRate: heartRate.map { Int(round($0)) },
            sourceName: "Apple Health"
        )
        
        let _: SyncResponse = try await networkManager.request(
            endpoint: "/health-metrics/ios",
            method: .post,
            body: request,
            requiresAuth: true
        )
        
        print("✅ Синхронизирована тренировка #\(workoutId)")
    }
    
    // MARK: - Получить средний пульс за тренировку
    private func getAverageHeartRate(for workout: HKWorkout) async throws -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let avgHeartRate = result?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: avgHeartRate)
            }
            
            healthStore.execute(query)
        }
    }
}
