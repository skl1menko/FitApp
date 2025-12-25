import Foundation
import HealthKit

class StepsService {
    
    private let healthStore = HKHealthStore()
    
    // Получение количества шагов за сегодня
    func getTodaySteps(completion: @escaping (Double) -> Void) {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: . strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: predicate, options: . cumulativeSum) { _, result, error in
            
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            
            let steps = sum.doubleValue(for: HKUnit.count())
            completion(steps)
        }
        
        healthStore.execute(query)
    }
    
    
    // Наблюдение за изменениями шагов
    func observeStepCount(completion: @escaping () -> Void) {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        let query = HKObserverQuery(sampleType: stepCountType, predicate: nil) { _, _, error in
            if error == nil {
                completion()
            }
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: stepCountType, frequency: .immediate) { _, _ in }
    }
}
