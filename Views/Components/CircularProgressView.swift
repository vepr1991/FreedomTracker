import SwiftUI

struct CircularProgressView: View {
    var percentage: Double
    var amount: String
    var subtitle: LocalizedStringKey
    var color: Color
    
    @State private var animatedPercentage: Double = 0
    
    var body: some View {
        ZStack {
            // 💡 Круг стал тоньше (10 вместо 12)
            Circle()
                .stroke(Color.primary.opacity(0.05), lineWidth: 10)
            
            Circle()
                .trim(from: 0, to: CGFloat(animatedPercentage / 100))
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.8), radius: 10)
                .animation(.easeOut(duration: 1.0), value: animatedPercentage)
                .animation(.easeInOut(duration: 0.5), value: color)
            
            VStack(spacing: 4) {
                Text(amount)
                    .contentTransition(.numericText())
                    // 💡 Шрифт суммы уменьшен (40 вместо 48), чтобы влезть в новый круг
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 20)
                
                Text(subtitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .tracking(2)
                    .foregroundStyle(color == .red ? .red : .secondary)
            }
        }
        // 💡 Уменьшили общий размер круга (с 280 до 240)
        .frame(width: 240, height: 240)
        .onAppear { animatedPercentage = percentage }
        .onChange(of: percentage) { oldValue, newValue in animatedPercentage = newValue }
    }
}
