import Foundation
import HealthKit

class WorkoutService {
    
    private let healthStore = HKHealthStore()
    
    func getWorkouts(for date: Date, completion: @escaping ([HKWorkout]) -> Void) {
        let workoutType = HKObjectType.workoutType()
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            
            guard let workouts = samples as? [HKWorkout], error == nil else {
                completion([])
                return
            }
            
            completion(workouts)
        }
        
        healthStore.execute(query)
    }
}
