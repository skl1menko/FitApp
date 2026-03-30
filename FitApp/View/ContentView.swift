import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var stepsViewModel = StepsViewModel()
    @StateObject private var caloriesViewModel = CaloriesViewModel()
    @StateObject private var heartViewModel =  HeartViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var syncViewModel = SyncViewModel()
    @State private var viewModel: ViewModel?
    @State private var selectedDate = Date()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient:  Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    
                    titleView
                    
                    datePicker
                    
                    metricsCards
                }
                .padding()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ViewModel(stepsViewModel: stepsViewModel, caloriesViewModel: caloriesViewModel, heartViewModel: heartViewModel, workoutViewModel: workoutViewModel)
                viewModel?.initialize()
            }
        }
        .alert("Ошибка", isPresented: Binding(
            get: { viewModel?.showError ?? false },
            set: { viewModel?.showError = $0 }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel?.errorMessage ?? "")
        }
        .alert("Успешно", isPresented: $syncViewModel.showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(syncViewModel.syncMessage ?? "")
        }
        .alert("Ошибка синхронизации", isPresented: $syncViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(syncViewModel.syncMessage ?? "")
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Spacer()
            
            Button(action: {
                authViewModel.logout()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Выход")
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.8))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    private var titleView: some View {
        Text("Мои показатели")
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.primary)
    }
    
    private var datePicker: some View {
        HStack(spacing: 10) {
            DatePicker("Выберите дату", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .padding()
                .background(Color.white)
                .frame(height: 50)
                .cornerRadius(15)
                .shadow(radius: 5)
                .onChange(of: selectedDate) { newDate in
                    loadData(for: newDate)
                }
            
            // Кнопка обновления
            Button(action: {
                viewModel?.refresh()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(15)
            .shadow(radius: 5)
            
            // Кнопка синхронизации
            Button(action: {
                Task {
                    await syncViewModel.syncMetricsOnly(
                        date: selectedDate,
                        steps: Double(stepsViewModel.stepCount),
                        calories: Double(caloriesViewModel.caloriesCount),
                        heartRate: heartViewModel.heartRate > 0 ? Double(heartViewModel.heartRate) : nil
                    )
                }
            }) {
                if syncViewModel.isSyncing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 50, height: 50)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(15)
            .shadow(radius: 5)
            .disabled(syncViewModel.isSyncing)
        }
    }
    
    private var metricsCards: some View {
        Group {
            HStack(spacing: 15) {
                StepsCard(stepCount: stepsViewModel.stepCount, isLoading: stepsViewModel.isLoading)
                    .frame(width: 190.0, height: 170.0)
                HeartCard(heartRate: heartViewModel.heartRate, isLoading: heartViewModel.isLoading)
                    .frame(width: 190.0, height: 170.0)
            }
            
            CaloriesCard(caloriesCount: caloriesViewModel.caloriesCount, isLoading: caloriesViewModel.isLoading)
                .frame(width: 395.0, height: 170.0)
            
            WorkoutCard(workouts: workoutViewModel.workouts, totalDuration: workoutViewModel.totalDuration, totalCalories: workoutViewModel.totalCalories, isLoading: workoutViewModel.isLoading, syncViewModel: syncViewModel, date: selectedDate)
                .frame(width: 395.0, height: 170.0)
        }
    }
    
    func loadData(for date: Date) {
        viewModel?.loadData(for: date)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
