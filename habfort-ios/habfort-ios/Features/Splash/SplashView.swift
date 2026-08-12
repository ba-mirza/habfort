import SwiftUI

struct SplashView: View {
    @State private var titleVisible = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            // Classic SwiftUI "gooey" trick: blur softens circle edges into
            // overlapping gradients, then alphaThreshold snaps the alpha back
            // to a hard edge — wherever blurred circles overlap, they read as
            // one merged liquid blob instead of two separate circles.
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.5, color: Color.accentColor))
                    context.addFilter(.blur(radius: 22))
                    context.drawLayer { layer in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        for i in 0..<5 {
                            let phase = time * 0.6 + Double(i) * 1.3
                            let x = size.width / 2 + cos(phase) * size.width * 0.24
                            let y = size.height / 2 + sin(phase * 1.3) * size.height * 0.28
                            let radius = 36.0 + sin(phase * 2) * 12
                            let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                            layer.fill(Path(ellipseIn: rect), with: .color(.accentColor))
                        }
                    }
                }
            }
            .frame(height: 280)

            VStack {
                Spacer()
                Text("Beles App")
                    .font(.largeTitle.bold())
                    .opacity(titleVisible ? 1 : 0)
                    .offset(y: titleVisible ? 0 : 8)
                Spacer()
            }
            .padding(.bottom, 60)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                titleVisible = true
            }
        }
    }
}
