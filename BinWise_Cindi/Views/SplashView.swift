import SwiftUI

/// Animated brand splash shown at cold start while Firebase checks auth state.
/// Fades + scales the logo in, then stays visible until the app's root routing
/// is ready — no internal timer, the parent decides when to dismiss it.
struct SplashView: View {

    @State private var logoScale: CGFloat   = 0.65
    @State private var logoOpacity: Double  = 0
    @State private var textOpacity: Double  = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()

            VStack(spacing: DS.Spacing.lg) {
                // Logo mark
                ZStack {
                    Circle()
                        .fill(DS.tealGradient)
                        .frame(width: 110, height: 110)
                        .shadow(color: DS.primary.opacity(0.35), radius: 20, x: 0, y: 10)
                    Image(systemName: "arrow.3.trianglepath")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // Wordmark
                VStack(spacing: DS.Spacing.xs) {
                    Text("BinWise")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(DS.primary)
                    Text("智能垃圾分类")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(DS.textSecondary)
                        .opacity(subtitleOpacity)
                }
                .opacity(textOpacity)
            }
        }
        .onAppear { animate() }
    }

    private func animate() {
        withAnimation(.spring(response: 0.65, dampingFraction: 0.70).delay(0.1)) {
            logoScale   = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.45)) {
            textOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.65)) {
            subtitleOpacity = 1.0
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
