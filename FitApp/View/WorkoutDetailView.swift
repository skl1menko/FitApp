import SwiftUI
import HealthKit

struct WorkoutDetailView: View {
    let workouts: [HKWorkout]
    let date: Date
    @ObservedObject var syncViewModel: SyncViewModel
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
                
                WorkoutSyncViewContent(
                    appleHealthWorkouts: workouts,
                    backendWorkouts: syncViewModel.backendWorkouts,
                    isLoading: syncViewModel.isLoadingWorkouts,
                    date: date
                )
            }
            .navigationTitle("Синхронизация тренировки")
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
    }
}
