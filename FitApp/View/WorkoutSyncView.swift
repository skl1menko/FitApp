//
//  WorkoutSyncView.swift
//  FitApp
//
//  Created by Sasha Klymenko on 27.03.2026.
//

import SwiftUI
import HealthKit

// MARK: - Standalone View (для модального окна, если нужно)
struct WorkoutSyncView: View {
    @StateObject private var viewModel = WorkoutSyncViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Выбор даты
                DatePicker("Training date", selection: $viewModel.selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding()
                    .background(Color(.systemGray6))
                    .onChange(of: viewModel.selectedDate) {
                        Task {
                            await viewModel.loadWorkouts()
                        }
                    }
                
                WorkoutSyncViewContent(
                    appleHealthWorkouts: viewModel.appleHealthWorkouts.map { $0.hkWorkout },
                    backendWorkouts: viewModel.backendWorkouts,
                    isLoading: viewModel.isLoading,
                    date: viewModel.selectedDate
                )
            }
            .navigationTitle("Training synchronization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadWorkouts()
            }
        }
    }
}

// MARK: - Content View (для встраивания в другие View)
struct WorkoutSyncViewContent: View {
    let appleHealthWorkouts: [HKWorkout]
    let backendWorkouts: [BackendWorkout]
    let isLoading: Bool
    let date: Date
    
    @State private var selectedAppleWorkout: HKWorkout?
    @State private var selectedBackendWorkout: BackendWorkout?
    @State private var isSyncing = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    private let healthSyncService = HealthSyncService.shared
    
    var body: some View {
        if isLoading {
            VStack {
                Spacer()
            ProgressView("Loading workouts...")
                    .padding()
                Spacer()
            }
        } else {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Секция Apple Health
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Apple Health")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                            
                            if appleHealthWorkouts.isEmpty {
                                emptyStateView(text: "Empty")
                            } else {
                                ForEach(appleHealthWorkouts, id: \.uuid) { workout in
                                    AppleWorkoutSyncCard(
                                        workout: workout,
                                        isSelected: selectedAppleWorkout?.uuid == workout.uuid
                                    )
                                    .onTapGesture {
                                        withAnimation {
                                            selectedAppleWorkout = workout
                                        }
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.vertical)
                        
                        // Секция Backend
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Backend trainings")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                            
                            if backendWorkouts.isEmpty {
                                emptyStateView(text: "Empty")
                            } else {
                                ForEach(backendWorkouts) { workout in
                                    BackendWorkoutSyncCard(
                                        workout: workout,
                                        isSelected: selectedBackendWorkout?.id == workout.id
                                    )
                                    .onTapGesture {
                                        withAnimation {
                                            selectedBackendWorkout = workout
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Сообщения об ошибках/успехе
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        
                        if let success = successMessage {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(success)
                                    .foregroundColor(.green)
                            }
                            .font(.caption)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                
                // Кнопка синхронизации
                Button(action: syncWorkouts) {
                    HStack {
                        if isSyncing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Synchronize")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSync ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                }
                .disabled(!canSync)
            }
        }
    }
    
    private var canSync: Bool {
        selectedAppleWorkout != nil && selectedBackendWorkout != nil && !isSyncing
    }
    
    private func syncWorkouts() {
        guard let appleWorkout = selectedAppleWorkout,
              let backendWorkout = selectedBackendWorkout else {
            errorMessage = "Select both workouts to sync"
            return
        }
        
        Task {
            isSyncing = true
            errorMessage = nil
            successMessage = nil
            
            do {
                try await healthSyncService.syncWorkoutWithHKWorkout(
                    workoutId: backendWorkout.workoutId,
                    hkWorkout: appleWorkout
                )
                
                successMessage = "Workout successfully synchronized!"
                
                // Clear selection
                selectedAppleWorkout = nil
                selectedBackendWorkout = nil
                
            } catch {
            errorMessage = "Synchronization error: \(error.localizedDescription)"
            }
            
            isSyncing = false
        }
    }
    
    private func emptyStateView(text: String) -> some View {
        Text(text)
            .foregroundColor(.secondary)
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
    }
}

// MARK: - Apple Workout Sync Card
struct AppleWorkoutSyncCard: View {
    let workout: HKWorkout
    let isSelected: Bool
    
    private var workoutType: String {
        workout.workoutActivityType.name
    }
    
    private var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: workout.startDate)
    }
    
    private var formattedDuration: String {
        let duration = workout.duration
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
    
    private var formattedCalories: String? {
        guard let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) else { return nil }
        return "\(Int(calories)) kcal"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workoutType)
                    .font(.headline)
                
                HStack(spacing: 16) {
                    Label(formattedStartTime, systemImage: "clock")
                    Label(formattedDuration, systemImage: "timer")
                    if let calories = formattedCalories {
                        Label(calories, systemImage: "flame.fill")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .padding(.horizontal)
    }
}

// MARK: - Backend Workout Sync Card
struct BackendWorkoutSyncCard: View {
    let workout: BackendWorkout
    let isSelected: Bool
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutName ?? workout.programName ?? "Workout #\(workout.workoutId)")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    if let date = workout.workoutDateTime {
                        Label(formatTime(date), systemImage: "clock")
                    }
                    
                    if let calories = workout.caloriesBurned {
                    Label("\(Int(calories)) kcal", systemImage: "flame.fill")
                    } else {
                        Text("No calorie data available")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding()
        .background(isSelected ? Color.green.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
        )
        .padding(.horizontal)
    }
}

#Preview {
    WorkoutSyncView()
}
