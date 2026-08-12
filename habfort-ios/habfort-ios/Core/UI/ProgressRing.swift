import SwiftUI

/// A single-value ring that carries its meaning in the color: red when the
/// share is low, amber in the middle, green when it's good. No ticks or needle
/// — the number in the middle is the precise reading, the ring is the glance.
struct ProgressRing: View {
    /// 0...1, or nil when there's no data to show.
    let value: Double?
    let centerText: String
    let caption: String
    var lineWidth: CGFloat = 18

    @State private var animatedValue: Double = 0

    /// Three quarters of a circle, gap at the bottom, so the ends frame the
    /// caption instead of closing around it.
    private let arcFraction: Double = 0.75

    var body: some View {
        ZStack {
            arc(to: arcFraction)
                .stroke(Color.white.opacity(0.12), style: strokeStyle)

            arc(to: arcFraction * animatedValue)
                .stroke(valueColor, style: strokeStyle)

            VStack(spacing: 2) {
                Text(centerText)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, lineWidth * 2)
        }
        .onAppear { animate(to: value) }
        .onChange(of: value) { _, newValue in animate(to: newValue) }
    }

    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .round)
    }

    private var valueColor: Color {
        guard let value else { return .white.opacity(0.25) }
        switch value {
        case ..<0.4: return .red
        case ..<0.7: return .orange
        default: return .green
        }
    }

    /// Rotating the shape rather than the ZStack keeps the label upright.
    private func arc(to end: Double) -> some Shape {
        Circle()
            .trim(from: 0, to: max(0, end))
            .rotation(.degrees(135))
    }

    private func animate(to newValue: Double?) {
        withAnimation(.spring(response: 0.9, dampingFraction: 0.8)) {
            animatedValue = newValue ?? 0
        }
    }
}
