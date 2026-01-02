import Foundation
import Combine
import HealthKit

class WorkoutViewModel: ObservableObject {
    
    @Published var workouts: [HKWorkout] = []
    @Published var isLoading: Bool = false
    @Published var totalDuration: TimeInterval = 0
    @Published var totalCalories: Double = 0
    
    private let healthKitManager = HealthKitManager.shared
    private let workoutService = WorkoutService()
    
    func loadWorkouts(for date: Date = Date()) {
        isLoading = true
        
        workoutService.getWorkouts(for: date) { [weak self] workouts in
            DispatchQueue.main.async {
                self?.workouts = workouts
                self?.calculateTotals(workouts)
                self?.isLoading = false
            }
        }
    }
    
    private func calculateTotals(_ workouts: [HKWorkout]) {
        totalDuration = workouts.reduce(0) { $0 + $1.duration }
        totalCalories = workouts.reduce(0) { $0 + ($1.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0) }
    }
}
