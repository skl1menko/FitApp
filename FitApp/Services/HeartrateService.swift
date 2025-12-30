//
//  HeartrateService.swift
//  FitApp
//
//  Created by Sasha Klymenko on 26.12.2025.
//
import HealthKit
class HeartrateService{
    private let healthStore = HKHealthStore()
    
    func getHeartrate(for date: Date,completion: @escaping (Double) -> Void) {
        guard let heartrateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(0)
            return
            }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: . strictStartDate)
      
        
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
