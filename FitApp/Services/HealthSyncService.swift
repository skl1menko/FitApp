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
    
    // MARK: - Main daily synchronization
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
        
        print("✅ Day data synchronized for \(date)")
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
    
    // MARK: - Get HealthKit workouts for the day
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
    
  
    
    // MARK: - Sync metrics for a specific workout
    private func syncWorkoutMetrics(workoutId: Int, hkWorkout: HKWorkout) async throws {
        // Check if metrics already exist
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
            
            // If metrics exist - skip
            if !response.data.isEmpty {
                print("⚠️ Metrics for workout #\(workoutId) already exist, skipping")
                return
            }
        } catch {
            // Error or no metrics - continue
        }
        
        // Get data from HealthKit for this workout
        let calories = hkWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
        let heartRate = try? await getAverageHeartRate(for: hkWorkout)
        
        let request = SyncHealthMetricsRequest(
            workoutId: workoutId,
            periodType: "workout",
            startDate: hkWorkout.startDate,
            endDate: hkWorkout.endDate,
            stepCount: nil, // steps usually not needed for workouts
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
        
        print("✅ Workout #\(workoutId) synchronized")
    }
    
  
    
    // MARK: - Синхронизация с конкретным выбранным HKWorkout
    func syncWorkoutWithHKWorkout(workoutId: Int, hkWorkout: HKWorkout) async throws {
        try await syncWorkoutMetrics(workoutId: workoutId, hkWorkout: hkWorkout)
        
        if let calories = hkWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie()), calories > 0 {
            try await updateWorkoutCalories(workoutId: workoutId, calories: calories)
        }
        print("✅ Workout #\(workoutId) synchronized with HKWorkout \(hkWorkout.startDate)")
    }
    
    // MARK: - Обновить calories_burned тренировки на бекенде
    private func updateWorkoutCalories(workoutId: Int, calories: Double) async throws {
        let request = UpdateWorkoutCaloriesRequest(caloriesBurned: calories)
        let _: SyncResponse = try await networkManager.request(
            endpoint: "/workouts/\(workoutId)",
            method: .put,
            body: request,
            requiresAuth: true
        )
        print("🔥 Calories (\(Int(calories)) kcal) saved to workout #\(workoutId)")
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

enum SyncError: LocalizedError {
    case notFound(String)
    
    var errorDescription: String? {
        switch self {
        case .notFound(let message): return message
        }
    }
}
