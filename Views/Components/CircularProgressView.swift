import SwiftUI

struct CircularProgressView: View {
    var percentage: Double
    var amount: String
    var subtitle: LocalizedStringKey
    var color: Color
    
    @State private var animatedPercentage: Double = 0
    
    var body: some View {
        ZStack {
            // 💡 Адаптивный серый круг
            Circle()
                .stroke(Color.primary.opacity(0.05), lineWidth: 12)
            
            Circle()
                .trim(from: 0, to: CGFloat(animatedPercentage / 100))
                .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.8), radius: 10)
                .animation(.easeOut(duration: 1.0), value: animatedPercentage)
                .animation(.easeInOut(duration: 0.5), value: color)
            
            VStack(spacing: 4) {
                Text(amount)
                    .contentTransition(.numericText())
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary) // 💡 Текст суммы под цвет темы
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 20)
                
                Text(subtitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .tracking(2)
                    // 💡 Подкрашиваем подпись, вторичным цветом если все ок
                    .foregroundStyle(color == .red ? .red : .secondary)
            }
        }
        .frame(width: 280, height: 280)
        .onAppear { animatedPercentage = percentage }
        .onChange(of: percentage) { oldValue, newValue in animatedPercentage = newValue }
    }
}
