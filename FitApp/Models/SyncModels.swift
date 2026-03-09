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
struct BackendWorkout: Decodable {
    let workoutId: Int
    let workoutName: String?
    let userId: Int
    let programId: Int?
    let programName: String?
    let startTime: String
    let endTime: String?
    let totalTonnage: String?
    
    var id: Int {
        return workoutId
    }
    
    var workoutDateTime: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: startTime)
    }
}

struct WorkoutsResponse: Decodable {
    let status: String
    let data: [BackendWorkout]
}
