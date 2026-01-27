import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var stepsViewModel = StepsViewModel()
    @StateObject private var caloriesViewModel = CaloriesViewModel()
    @StateObject private var heartViewModel =  HeartViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
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
                    // Шапка с приветствием и кнопкой выхода
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Привет!")
                                .font(.title3)
                            if let user = authViewModel.currentUser {
                                Text(user.fullName)
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                        }
                        
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
                    
                    Text("Мои показатели")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    DatePicker("Выберите дату", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .onChange(of: selectedDate) { newDate in
                            loadData(for: newDate)
                        }
                    HStack(spacing: 15){
                        StepsCard(stepCount: stepsViewModel.stepCount, isLoading: stepsViewModel.isLoading)
                            .frame(width: 170, height: 170)
                        HeartCard(heartRate: heartViewModel.heartRate, isLoading: heartViewModel.isLoading)
                            .frame(width: 170, height: 170)
                    }
                    
                    CaloriesCard(caloriesCount: caloriesViewModel.caloriesCount, isLoading: caloriesViewModel.isLoading)
                        .frame(width: 355, height: 170)
                    
                    WorkoutCard(workouts: workoutViewModel.workouts, totalDuration: workoutViewModel.totalDuration, totalCalories: workoutViewModel.totalCalories, isLoading: workoutViewModel.isLoading)
                        .frame(width: 355, height: 170)
                    
                    if let viewModel = viewModel {
                        RefreshButton(action: viewModel.refresh)
                            .padding(.bottom, 20)
                    }
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
    }
    
    func loadData(for date: Date) {
        viewModel?.loadData(for: date)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
