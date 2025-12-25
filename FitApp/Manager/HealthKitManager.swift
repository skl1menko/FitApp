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
            let caloriesBurned = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        else {
            completion(false, nil)
            return
        }
        
        let typesToRead:  Set<HKObjectType> = [stepCount,caloriesBurned]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            completion(success, error)
        }
    }
}
