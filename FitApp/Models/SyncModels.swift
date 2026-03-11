//
//  SyncModels.swift
//  FitApp
//
//  Created by Sasha Klymenko on 27.01.2026.
//

import Foundation

// Запрос на синхронизацию метрик
struct SyncHealthMetricsRequest: Encodable {
    let workoutId: Int?
    let periodType: String // "daily", "workout"
    let startDate: Date
    let endDate: Date
    let stepCount: Int?
    let totalEnergyBurned: Double?
    let avgHeartRate: Int?
    let sourceName: String
    
    enum CodingKeys: String, CodingKey {
        case workoutId = "workout_id"
        case periodType = "period_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case stepCount = "step_count"
        case totalEnergyBurned = "total_energy_burned"
        case avgHeartRate = "avg_heart_rate"
        case sourceName = "source_name"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(workoutId, forKey: .workoutId)
        try container.encode(periodType, forKey: .periodType)
        try container.encodeIfPresent(stepCount, forKey: .stepCount)
        try container.encodeIfPresent(totalEnergyBurned, forKey: .totalEnergyBurned)
        try container.encodeIfPresent(avgHeartRate, forKey: .avgHeartRate)
        try container.encode(sourceName, forKey: .sourceName)
        
        // Форматируем даты в локальном часовом поясе
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone.current
        
        try container.encode(formatter.string(from: startDate), forKey: .startDate)
        try container.encode(formatter.string(from: endDate), forKey: .endDate)
    }
}

// Ответ от backend
struct SyncResponse: Decodable {
    let status: String
    let message: String
}

// Модель тренировки из backend
struct BackendWorkout: Decodable, Identifiable {
    let workoutId: Int
    let workoutName: String?
    let userId: Int
    let programId: Int?
    let programName: String?
    let startTime: String
    let endTime: String?
    let totalTonnage: String?
    let caloriesBurned: Double?
    
    enum CodingKeys: String, CodingKey {
        case workoutId, workoutName, userId, programId, programName
        case startTime, endTime, totalTonnage, caloriesBurned
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        workoutId    = try c.decode(Int.self, forKey: .workoutId)
        workoutName  = try c.decodeIfPresent(String.self, forKey: .workoutName)
        userId       = try c.decode(Int.self, forKey: .userId)
        programId    = try c.decodeIfPresent(Int.self, forKey: .programId)
        programName  = try c.decodeIfPresent(String.self, forKey: .programName)
        startTime    = try c.decode(String.self, forKey: .startTime)
        endTime      = try c.decodeIfPresent(String.self, forKey: .endTime)
        totalTonnage = try c.decodeIfPresent(String.self, forKey: .totalTonnage)
        // PostgreSQL NUMERIC приходит как строка или число — обрабатываем оба варианта
        if let asDouble = try? c.decodeIfPresent(Double.self, forKey: .caloriesBurned) {
            caloriesBurned = asDouble
        } else if let asString = try? c.decodeIfPresent(String.self, forKey: .caloriesBurned) {
            caloriesBurned = Double(asString)
        } else {
            caloriesBurned = nil
        }
    }
    
    var id: Int { workoutId }
    
    var workoutDateTime: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: startTime) { return date }
        // Fallback без миллисекунд
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: startTime)
    }
}

// Запрос на обновление калорий тренировки
struct UpdateWorkoutCaloriesRequest: Encodable {
    let caloriesBurned: Double
    
    enum CodingKeys: String, CodingKey {
        case caloriesBurned = "calories_burned"
    }
}

struct WorkoutsResponse: Decodable {
    let status: String
    let data: [BackendWorkout]
}
