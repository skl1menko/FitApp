//
//  WorkoutSyncModels.swift
//  FitApp
//
//  Created by Sasha Klymenko on 27.03.2026.
//

import Foundation
import HealthKit

// Модель тренировки из Apple Health для UI
struct AppleHealthWorkout: Identifiable {
    let id: UUID
    let hkWorkout: HKWorkout
    let workoutType: String
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let calories: Double?
    
    init(hkWorkout: HKWorkout) {
        self.id = hkWorkout.uuid
        self.hkWorkout = hkWorkout
        self.workoutType = hkWorkout.workoutActivityType.name
        self.startDate = hkWorkout.startDate
        self.endDate = hkWorkout.endDate
        self.duration = hkWorkout.duration
        self.calories = hkWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
    }
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: startDate)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
    
    var formattedCalories: String? {
        guard let calories = calories else { return nil }
        return "\(Int(calories)) kcal"
    }
}

// Расширение для получения читабельного названия типа тренировки
extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Functional Strength Training"
        case .traditionalStrengthTraining: return "Strength Training"
        case .crossTraining: return "Cross Training"
        case .hiking: return "Hiking"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stair Climbing"
        case .dance: return "Dance"
        case .basketball: return "Basketball"
        case .soccer: return "Soccer"
        case .tennis: return "Tennis"
        case .boxing: return "Boxing"
        case .martialArts: return "Martial Arts"
        case .climbing: return "Climbing"
        case .downhillSkiing: return "Downhill Skiing"
        case .snowboarding: return "Snowboarding"
        case .other: return "Other"
        default: return "Workout"
        }
    }
}
