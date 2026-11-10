import SwiftUI

/// Paper backdrop: cold grey wash, fine vertical ruling and the ghost of a
/// vinyl groove bleeding off the lower-right corner.
struct Backdrop: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0xEEF0F3), Color(hex: 0xE2E6EB), Color(hex: 0xE9ECF0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Canvas { ctx, size in
                    var path = Path()
                    var x: CGFloat = 0
                    while x < size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        x += 4
                    }
                    ctx.stroke(path, with: .color(.white.opacity(0.55)), lineWidth: 0.6)
                }
                .blendMode(.softLight)

                RecordGrooves()
                    .frame(width: geo.size.width * 1.35, height: geo.size.width * 1.35)
                    .position(x: geo.size.width * 1.02, y: geo.size.height * 0.66)
                    .opacity(0.55)
            }
        }
        .ignoresSafeArea()
    }
}

private struct RecordGrooves: View {
    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(0..<26, id: \.self) { i in
                    Circle()
                        .stroke(Ink.navy.opacity(0.055), lineWidth: 0.7)
                        .frame(width: d - CGFloat(i) * d * 0.032)
                }
                Circle()
                    .stroke(Ink.navy.opacity(0.07), lineWidth: 1.2)
                    .frame(width: d * 0.28)
            }
            .frame(width: d, height: d)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}
