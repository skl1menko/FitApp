import SwiftUI
import HealthKit

struct WorkoutCard: View {
    let workouts: [HKWorkout]
    let totalDuration: TimeInterval
    let totalCalories: Double
    let isLoading: Bool
    let syncViewModel: SyncViewModel
    let date: Date
    @State private var showDetails = false
    
    var workoutCount: Int {
        workouts.count
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else {
                    VStack(spacing: geometry.size.height * 0.05) {
                        HStack {
                            Image(systemName: "figure.run")
                                .font(.system(size: geometry.size.height * 0.2))
                                .foregroundColor(.orange)
                            
                            Spacer()
                            
                            Text("\(workoutCount)")
                                .font(.system(size: geometry.size.height * 0.25, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, geometry.size.width * 0.1)
                        
                        HStack(spacing: geometry.size.width * 0.15) {
                            VStack(spacing: 5) {
                                Text(formatDuration(totalDuration))
                                    .font(.system(size: geometry.size.height * 0.15, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("Duration")
                                    .font(.system(size: geometry.size.height * 0.1, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(spacing: 5) {
                                Text(String(format: "%.0f", totalCalories))
                                    .font(.system(size: geometry.size.height * 0.15, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("Calories")
                                    .font(.system(size: geometry.size.height * 0.1, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("Workouts")
                            .font(.system(size: geometry.size.height * 0.12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, geometry.size.height * 0.05)
                }
            }
        }
        .animation(.spring(), value: workoutCount)
        .onTapGesture {
            showDetails = true
        }
        .sheet(isPresented: $showDetails) {
            WorkoutDetailView(workouts: workouts, date: date, syncViewModel: syncViewModel)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
