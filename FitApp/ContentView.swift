import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = StepsViewModel()
    
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
                        StepsCard(stepCount: viewModel.stepCount, isLoading: viewModel.isLoading)
                            .frame(width: 170, height: 170)
                        StepsCard(stepCount: viewModel.stepCount, isLoading: viewModel.isLoading)
                            . frame(width: 170, height: 170)
                    }
                    
                    // Вторая строка - одна карточка
                    StepsCard(stepCount: viewModel.stepCount, isLoading: viewModel.isLoading)
                        .frame(width: 355, height: 170)
                    
                    // Кнопка обновления
                    RefreshButton(action: viewModel.refresh)
                        .padding(. bottom, 20)
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.initialize()
        }
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Компонент карточки с шагами (адаптивный)
struct StepsCard: View {
    let stepCount: Int
    let isLoading: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y:  5)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else {
                    VStack(spacing: geometry.size.height * 0.05) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: geometry.size.height * 0.25))
                            .foregroundColor(.blue)
                        
                        Text("\(stepCount)")
                            .font(.system(size: geometry.size.height * 0.3, weight: .bold))
                            .foregroundColor(.primary)
                            .transition(.scale)
                            .minimumScaleFactor(0.5)
                        
                        Text("шагов")
                            .font(.system(size: geometry.size.height * 0.12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .animation(.spring(), value: stepCount)
    }
}
// MARK: - Компонент кнопки обновления
struct RefreshButton: View {
    let action: () -> Void
    
    var body:  some View {
        Button(action: action) {
            HStack {
                Image(systemName:  "arrow.clockwise")
                Text("Обновить")
            }
            .font(. system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 200, height: 50)
            .background(Color.blue)
            .cornerRadius(15)
        }
    }
}

#Preview {
    ContentView()
}
