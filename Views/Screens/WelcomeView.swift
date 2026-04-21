import SwiftUI

struct WelcomeView: View {
    @Binding var hasSeenTutorial: Bool
    
    var body: some View {
        ZStack {
            // 💡 ИСПРАВЛЕНИЕ: Системный фон вместо черного
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                
                VStack(spacing: 16) {
                    Text("Welcome to DayLimit")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary) // 💡 Адаптивный текст
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Your daily allowance tracker. Spend your money without complex spreadsheets and guilt.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary) // 💡 Вторичный текст
                        .padding(.horizontal, 32)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    FeatureRow(icon: "bolt.fill", color: .yellow, title: "Lightning Fast", subtitle: "Log expenses instantly via Lock Screen widget or Siri.")
                    FeatureRow(icon: "moon.stars.fill", color: .blue, title: "Midnight Reset", subtitle: "Overspent today? Tomorrow is a clean slate. No stress.")
                    FeatureRow(icon: "envelope.fill", color: .cyan, title: "Dream Envelope", subtitle: "Unspent daily limit goes straight towards your big goals.")
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                Button(action: {
                    withAnimation { hasSeenTutorial = true }
                }) {
                    Text("GET STARTED")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct FeatureRow: View {
    var icon: String
    var color: Color
    var title: LocalizedStringKey
    var subtitle: LocalizedStringKey
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary) // 💡 Адаптивный текст
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary) // 💡 Адаптивный текст
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
