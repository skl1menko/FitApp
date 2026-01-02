//
//  HealthKitManager.swift
//  FitApp
//
//  Created by Sasha Klymenko on 25.12.2025.
//

import Foundation
import HealthKit

class HealthKitManager {
    
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    private init() {}
    
    // Проверка доступности HealthKit
    func isHealthKitAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    // Запрос разрешений
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard
            let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount),
            let caloriesBurned = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)
        else {
            completion(false, nil)
            return
        }
        
        let workoutType = HKObjectType.workoutType()
        
        let typesToRead:  Set<HKObjectType> = [stepCount, caloriesBurned, heartRate, workoutType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            completion(success, error)
        }
    }
}
