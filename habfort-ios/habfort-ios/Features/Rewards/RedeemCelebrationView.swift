import SwiftUI

struct RedeemCelebration: Identifiable {
    let id = UUID()
    let rewardName: String
    let isFirst: Bool
}

/// Full-screen "you earned it" moment after every redeem — the payoff the
/// whole habit loop builds towards, so it gets more than a list refresh.
struct RedeemCelebrationView: View {
    let celebration: RedeemCelebration
    let onClose: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ConfettiView()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "gift.fill")
                    .font(.system(size: 96))
                    .foregroundStyle(.white)
                    .scaleEffect(appeared ? 1 : 0.2)
                    .rotationEffect(.degrees(appeared ? 0 : -25))
                Text(celebration.isFirst ? "Первая награда!" : "Награда получена!")
                    .font(.largeTitle.bold())
                Text("«\(celebration.rewardName)» — заслужено. Наслаждайся!")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                Button(action: onClose) {
                    Text("Ура!")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(Color.accentColor)
                .controlSize(.large)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .foregroundStyle(.white)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) { appeared = true }
        }
        .sensoryFeedback(.success, trigger: appeared)
    }
}

/// Confetti falling from above the top edge, drawn in a Canvas so a hundred
/// pieces stay cheap.
private struct ConfettiView: View {
    private struct Piece {
        let x: Double, delay: Double, speed: Double, spin: Double, size: Double, color: Color
    }

    private let pieces: [Piece] = (0..<120).map { _ in
        Piece(
            x: .random(in: 0...1),
            delay: .random(in: 0...1.5),
            speed: .random(in: 0.25...0.5),
            spin: .random(in: 2...6),
            size: .random(in: 6...11),
            color: [.yellow, .white, .pink, .green, .orange, .cyan].randomElement()!
        )
    }
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(start)
                for piece in pieces {
                    let t = elapsed - piece.delay
                    guard t > 0 else { continue }
                    let y = -20 + t * piece.speed * size.height
                    guard y < size.height + 20 else { continue }
                    let x = piece.x * size.width + sin(t * piece.spin) * 18
                    var pieceContext = context
                    pieceContext.translateBy(x: x, y: y)
                    pieceContext.rotate(by: .radians(t * piece.spin))
                    pieceContext.fill(
                        Path(CGRect(x: -piece.size / 2, y: -piece.size / 4, width: piece.size, height: piece.size / 2)),
                        with: .color(piece.color)
                    )
                }
            }
        }
        .accessibilityHidden(true)
    }
}
