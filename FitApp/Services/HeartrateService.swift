//
//  HeartrateService.swift
//  FitApp
//
//  Created by Sasha Klymenko on 26.12.2025.
//
import HealthKit
class HeartrateService{
    private let healthStore = HKHealthStore()
    
    func getTodayHeartrate(completion: @escaping (Double) -> Void) {
        guard let heartrateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(0)
            return
            }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: heartrateType, quantitySamplePredicate: predicate, options: .discreteAverage) { (query, result, error) in
            guard let result = result, let avg = result.averageQuantity() else {
                completion(0)
                return
            }
            
            let heartrate = avg.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            completion(heartrate)
        }
        healthStore.execute(query)
    }
}
