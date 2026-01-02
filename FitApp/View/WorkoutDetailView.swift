import SwiftUI
import HealthKit

struct WorkoutDetailView: View {
    let workouts: [HKWorkout]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if workouts.isEmpty {
                    VStack {
                        Image(systemName: "figure.run.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        Text("No workouts for this day")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding()
                    }
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
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

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
