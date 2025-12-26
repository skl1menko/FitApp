import SwiftUI

struct ContentView: View {
    @StateObject private var stepsViewModel = StepsViewModel()
    @StateObject private var caloriesViewModel = CaloriesViewModel()
    @StateObject private var heartViewModel =  HeartViewModel()
    @State private var viewModel: ViewModel?
    
    
    var body: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(
                gradient:  Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: . topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing:  20) {
                    Text("Мои шаги")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(. primary)
                        .padding(.top, 20)
                    
                    // Первая строка - две карточки
                    HStack(spacing: 15) {
                        StepsCard(stepCount: stepsViewModel.stepCount, isLoading: stepsViewModel.isLoading)
                            .frame(width: 170, height: 170)
                        HeartCard(heartRate: heartViewModel.heartRate, isLoading: heartViewModel.isLoading)
                            . frame(width: 170, height: 170)
                    }
                    
                    // Вторая строка - одна карточка
                    CaloriesCard(caloriesCount: caloriesViewModel.caloriesCount, isLoading: caloriesViewModel.isLoading)
                        .frame(width: 355, height: 170)
                    
                    // Кнопка обновления
                    if let viewModel = viewModel {
                        RefreshButton(action: viewModel.refresh)
                            .padding(. bottom, 20)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ViewModel(stepsViewModel: stepsViewModel, caloriesViewModel: caloriesViewModel)
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
}



#Preview {
    ContentView()
}
