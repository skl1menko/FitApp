import Foundation
import HealthKit

class StepsService {
    
    private let healthStore = HKHealthStore()
    
    // Получение количества шагов за сегодня
    func getSteps(for date: Date, completion: @escaping (Double) -> Void) {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: . strictStartDate)
      
        
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
    
}
