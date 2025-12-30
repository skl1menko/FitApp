//
//  CaloriesService.swift
//  FitApp
//
//  Created by Sasha Klymenko on 26.12.2025.
//
import Foundation
import HealthKit

class CaloriesService{
    private  let healthStore = HKHealthStore()
    
    func getCalories(for date: Date,completion: @escaping (Double) -> Void) {
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0)
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: . strictStartDate)
      
        
        let query = HKStatisticsQuery(quantityType: caloriesType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (query, result, error) in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            
            let calories = sum.doubleValue(for: HKUnit.kilocalorie())
            completion(calories)
        }
        
        healthStore.execute(query)

        
    }
    
    
}
