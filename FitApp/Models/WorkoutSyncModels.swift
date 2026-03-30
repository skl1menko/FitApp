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
            return "\(hours)ч \(minutes)мин"
        } else {
            return "\(minutes)мин"
        }
    }
    
    var formattedCalories: String? {
        guard let calories = calories else { return nil }
        return "\(Int(calories)) ккал"
    }
}

// Расширение для получения читабельного названия типа тренировки
extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Бег"
        case .cycling: return "Велоспорт"
        case .walking: return "Ходьба"
        case .swimming: return "Плавание"
        case .yoga: return "Йога"
        case .functionalStrengthTraining: return "Силовая тренировка"
        case .traditionalStrengthTraining: return "Силовая тренировка"
        case .crossTraining: return "Кросс-тренинг"
        case .hiking: return "Пеший туризм"
        case .elliptical: return "Эллиптический тренажер"
        case .rowing: return "Гребля"
        case .stairClimbing: return "Подъем по лестнице"
        case .dance: return "Танцы"
        case .basketball: return "Баскетбол"
        case .soccer: return "Футбол"
        case .tennis: return "Теннис"
        case .boxing: return "Бокс"
        case .martialArts: return "Боевые искусства"
        case .climbing: return "Скалолазание"
        case .downhillSkiing: return "Лыжи"
        case .snowboarding: return "Сноуборд"
        case .other: return "Другое"
        default: return "Тренировка"
        }
    }
}
