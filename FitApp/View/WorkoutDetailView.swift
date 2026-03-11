import SwiftUI
import HealthKit

struct WorkoutDetailView: View {
    let workouts: [HKWorkout]
    let date: Date
    @ObservedObject var syncViewModel: SyncViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    @State private var workoutToSync: BackendWorkout? = nil  // бекенд-тренировка ожидающая выбора HK
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Picker("", selection: $selectedTab) {
                        Text("HealthKit").tag(0)
                        Text("Бекенд").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    if selectedTab == 0 {
                        healthKitTab
                    } else {
                        backendTab
                    }
                }
            }
            .navigationTitle("Тренировки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
        .onAppear {
            Task { await syncViewModel.loadBackendWorkouts(for: date) }
        }
        .sheet(item: $workoutToSync) { backendWorkout in
            HKWorkoutPickerView(
                backendWorkout: backendWorkout,
                healthKitWorkouts: workouts,
                date: date
            ) { hkWorkout in
                workoutToSync = nil
                Task { await syncViewModel.syncWorkoutWithSelected(backendWorkout, hkWorkout: hkWorkout) }
            }
        }
        .alert("Ошибка синхронизации", isPresented: Binding(
            get: { syncViewModel.workoutSyncError != nil },
            set: { if !$0 { syncViewModel.workoutSyncError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(syncViewModel.workoutSyncError ?? "")
        }
    }
    
    // MARK: - HealthKit Tab
    private var healthKitTab: some View {
        Group {
            if workouts.isEmpty {
                emptyState(icon: "figure.run.circle", text: "Нет тренировок в HealthKit\nза этот день")
            } else {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(workouts, id: \.uuid) { workout in
                            WorkoutRowView(workout: workout)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Backend Tab
    private var backendTab: some View {
        Group {
            if syncViewModel.isLoadingWorkouts {
                Spacer()
                ProgressView("Загрузка...")
                    .scaleEffect(1.2)
                Spacer()
            } else if syncViewModel.backendWorkouts.isEmpty {
                emptyState(icon: "server.rack", text: "Нет тренировок на бекенде\nза этот день")
            } else {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(syncViewModel.backendWorkouts, id: \.workoutId) { workout in
                            BackendWorkoutRowView(
                                workout: workout,
                                isSyncing: syncViewModel.syncingWorkoutId == workout.id,
                                isSynced: syncViewModel.syncedWorkoutIds.contains(workout.id)
                            ) {
                                workoutToSync = workout  // открыть пикер
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.6))
            Text(text)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Backend Workout Row
struct BackendWorkoutRowView: View {
    let workout: BackendWorkout
    let isSyncing: Bool
    let isSynced: Bool
    let onSync: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Кнопка синхронизации — слева
            syncButton
            
            // Иконка и информация
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 28))
                .foregroundColor(.orange)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutName ?? "Тренировка #\(workout.workoutId)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let date = workout.workoutDateTime {
                    Text(formatTime(date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Калории справа
            VStack(alignment: .trailing, spacing: 2) {
                if let cal = workout.caloriesBurned {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("\(Int(cal))")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text("ккал")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                if let tonnage = workout.totalTonnage {
                    Text("\(tonnage) кг")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var syncButton: some View {
        if isSyncing {
            ProgressView()
                .frame(width: 36, height: 36)
        } else if isSynced {
            // Синхронизировано в этой сессии
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.green)
                .frame(width: 36, height: 36)
        } else {
            Button(action: onSync) {
                Image(systemName: workout.caloriesBurned != nil
                      ? "arrow.triangle.2.circlepath.circle"      // уже есть данные — обновить
                      : "arrow.triangle.2.circlepath.circle.fill" // нет данных — синхронизировать
                )
                .font(.system(size: 28))
                .foregroundColor(workout.caloriesBurned != nil ? .orange : .blue)
            }
            .frame(width: 36, height: 36)
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - HealthKit Workout Row (без изменений)
struct WorkoutRowView: View {
    let workout: HKWorkout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: workoutIcon)
                    .font(.system(size: 30))
                    .foregroundColor(workoutColor)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(formatTime(workout.startDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack(spacing: 20) {
                StatView(icon: "clock.fill", value: formatDuration(workout.duration), label: "Duration")
                StatView(icon: "flame.fill", value: String(format: "%.0f", workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0), label: "Calories")
                
                if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
                    StatView(icon: "figure.walk", value: String(format: "%.2f km", distance / 1000), label: "Distance")
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var workoutName: String {
        switch workout.workoutActivityType {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Weight Training"
        case .crossTraining: return "Cross Training"
        case .hiking: return "Hiking"
        case .dance: return "Dance"
        case .tennis: return "Tennis"
        case .basketball: return "Basketball"
        case .soccer: return "Soccer"
        default: return "Workout"
        }
    }
    
    private var workoutIcon: String {
        switch workout.workoutActivityType {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.mind.and.body"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "dumbbell.fill"
        case .crossTraining: return "figure.cross.training"
        case .hiking: return "figure.hiking"
        case .dance: return "figure.dance"
        case .tennis: return "tennis.racket"
        case .basketball: return "basketball.fill"
        case .soccer: return "soccerball"
        default: return "figure.mixed.cardio"
        }
    }
    
    private var workoutColor: Color {
        switch workout.workoutActivityType {
        case .running: return .orange
        case .walking: return .green
        case .cycling: return .blue
        case .swimming: return .cyan
        case .yoga: return .purple
        case .functionalStrengthTraining, .traditionalStrengthTraining: return .red
        default: return .orange
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct StatView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.orange)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - HealthKit Workout Picker
struct HKWorkoutPickerView: View {
    let backendWorkout: BackendWorkout
    let healthKitWorkouts: [HKWorkout]
    let date: Date
    let onSelect: (HKWorkout) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Бекенд-тренировка (для какой выбираем)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Синхронизировать тренировку:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(backendWorkout.workoutName ?? "Тренировка #\(backendWorkout.workoutId)")
                            .font(.headline)
                        if let dt = backendWorkout.workoutDateTime {
                            Text(formatDateTime(dt))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                    .padding()
                    
                    if healthKitWorkouts.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "applewatch.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.6))
                            Text("Нет тренировок в HealthKit\nза этот день")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        Text("Выберите тренировку из HealthKit:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(healthKitWorkouts, id: \.uuid) { hkWorkout in
                                    HKWorkoutPickerRow(workout: hkWorkout) {
                                        onSelect(hkWorkout)
                                        dismiss()
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Выбор тренировки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct HKWorkoutPickerRow: View {
    let workout: HKWorkout
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: workoutIcon)
                    .font(.system(size: 26))
                    .foregroundColor(workoutColor)
                    .frame(width: 44, height: 44)
                    .background(workoutColor.opacity(0.12))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(workoutName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    HStack(spacing: 12) {
                        Label(formatTime(workout.startDate), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Label(formatDuration(workout.duration), systemImage: "timer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if let cal = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()), cal > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill").foregroundColor(.red).font(.caption2)
                            Text("\(Int(cal))").font(.system(size: 13, weight: .semibold))
                        }
                        Text("ккал").font(.caption2).foregroundColor(.secondary)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var workoutName: String {
        switch workout.workoutActivityType {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Weight Training"
        case .crossTraining: return "Cross Training"
        case .hiking: return "Hiking"
        default: return "Workout"
        }
    }
    
    private var workoutIcon: String {
        switch workout.workoutActivityType {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.mind.and.body"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "dumbbell.fill"
        case .crossTraining: return "figure.cross.training"
        case .hiking: return "figure.hiking"
        default: return "figure.mixed.cardio"
        }
    }
    
    private var workoutColor: Color {
        switch workout.workoutActivityType {
        case .running: return .orange
        case .walking: return .green
        case .cycling: return .blue
        case .swimming: return .cyan
        case .yoga: return .purple
        case .functionalStrengthTraining, .traditionalStrengthTraining: return .red
        default: return .orange
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; f.dateStyle = .none
        return f.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600, m = Int(duration) / 60 % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}