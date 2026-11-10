import SwiftUI

// MARK: - Stage

/// The inset "compact disc" bay: jewel case on the left, disc resting over it.
struct CDStage: View {
    let song: Song?
    let angle: Double
    var onTap: () -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xEFF3F9), Color(hex: 0xD9E2F0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Canvas { ctx, size in
                    var path = Path()
                    var x = -size.height
                    while x < size.width {
                        path.move(to: CGPoint(x: x, y: size.height))
                        path.addLine(to: CGPoint(x: x + size.height, y: 0))
                        x += 7
                    }
                    ctx.stroke(path, with: .color(.white.opacity(0.45)), lineWidth: 0.6)
                }

                CDCase(song: song)
                    .frame(width: w * 0.585, height: h * 0.715)
                    .offset(x: -w * 0.155, y: h * 0.018)
                    .zIndex(1)

                CompactDisc(song: song, angle: angle)
                    .frame(width: h * 0.820, height: h * 0.820)
                    .offset(x: w * 0.155, y: -h * 0.004)
                    .shadow(color: Ink.navy.opacity(0.32), radius: 12, x: 4, y: 8)
                    .zIndex(2)
            }
            .overlay(alignment: .topLeading) {
                MonoText(text: "COMPACT DISC", size: 6, color: Ink.hairline.opacity(0.9), tracking: 1.1)
                    .padding(.horizontal, 8)
                    .padding(.top, 7)
            }
            .overlay(alignment: .topTrailing) {
                MonoText(text: "DIGITAL / 48", size: 6, color: Ink.hairline.opacity(0.9), tracking: 1.1)
                    .padding(.horizontal, 8)
                    .padding(.top, 7)
            }
            .overlay(alignment: .bottomLeading) {
                MonoText(text: "A VINYL", size: 5.5, color: Ink.hairline.opacity(0.75), tracking: 1.1)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
            }
            .overlay(alignment: .bottomTrailing) {
                MonoText(text: "LWK-006", size: 5.5, color: Ink.hairline.opacity(0.75), tracking: 1.1)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
            }
        }
        .frame(height: 298)
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(Ink.hairline.opacity(0.5), lineWidth: 0.7)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

// MARK: - Jewel case

private struct CDCase: View {
    let song: Song?

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            HStack(spacing: 0) {
                spine(width: w * 0.185, height: h)
                art(width: w * 0.815 - 8, height: h - 8)
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color(hex: 0xF5F7FB))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(Color.white, lineWidth: 1.2)
                    )
                    .shadow(color: .black.opacity(0.22), radius: 7, x: 4, y: 6)
            )
        }
    }

    private var spineText: String {
        let raw = song?.title ?? "no track"
        return raw.uppercased()
    }

    private func spine(width: CGFloat, height: CGFloat) -> some View {
        let count = max(1, spineText.count)
        let fitted = (height * 0.84) / (CGFloat(count) * 0.47)
        let size = min(width * 0.62, fitted)

        return ZStack {
            LinearGradient(
                colors: [Color(hex: 0xE6EDFA), Color(hex: 0xC9D8F0)],
                startPoint: .top,
                endPoint: .bottom
            )

            Text(spineText)
                .font(Typo.display(size))
                .foregroundColor(Ink.blue.opacity(0.92))
                .lineLimit(1)
                .fixedSize()
                .rotationEffect(.degrees(-90))
        }
        .frame(width: width, height: height)
        .clipped()
    }

    @ViewBuilder
    private func art(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if let data = song?.artwork, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: 0xC9D7EC), Color(hex: 0x41639F), Color(hex: 0x11274F)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Circle()
                        .fill(Color.white.opacity(0.30))
                        .frame(width: width * 1.1)
                        .blur(radius: 22)
                        .offset(x: -width * 0.35, y: -height * 0.28)
                    Circle()
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                        .frame(width: width * 0.55)
                        .offset(y: -height * 0.02)
                    Sparkle(size: width * 0.17, color: .white.opacity(0.85))
                        .offset(x: width * 0.24, y: -height * 0.10)
                }
                .frame(width: width, height: height)
                .clipped()
            }

            MonoText(text: "LUNAK", size: 5, color: .white.opacity(0.85), tracking: 1.4)
                .padding(5)
        }
        .overlay(alignment: .topTrailing) {
            Text("06")
                .font(Typo.mono(6, .bold))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(Ink.blue.opacity(0.85))
                .padding(5)
        }
    }
}

// MARK: - Disc

private struct CompactDisc: View {
    let song: Song?
    let angle: Double

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)

            ZStack {
                discSurface(d)
                    .rotationEffect(.degrees(angle))
                printedLabel(d)
            }
            .frame(width: d, height: d)
        }
    }

    private func discSurface(_ d: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(hex: 0x2F5CD4),
                            Color(hex: 0x152A66),
                            Color(hex: 0x5182EA),
                            Color(hex: 0x0E1E4C),
                            Color(hex: 0x2F5CD4)
                        ]),
                        center: .center
                    )
                )

            ForEach(1..<16, id: \.self) { i in
                Circle()
                    .stroke(Color.white.opacity(i % 3 == 0 ? 0.07 : 0.035), lineWidth: 0.8)
                    .frame(width: d * (0.40 + CGFloat(i) * 0.037))
            }

            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.42), .white.opacity(0.02), .white.opacity(0.20), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.screen)

            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1.1)
            Circle()
                .stroke(Ink.navy.opacity(0.4), lineWidth: 1)
                .padding(1.6)
        }
        .frame(width: d, height: d)
        .clipShape(Circle())
    }

    private func printedLabel(_ d: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0xF7F9FC))
                .frame(width: d * 0.395)
                .overlay(Circle().stroke(Color.black.opacity(0.10), lineWidth: 1))

            Circle()
                .fill(Color(hex: 0x15275C))
                .frame(width: d * 0.145)

            VStack(spacing: d * 0.012) {
                Text("lunak")
                    .font(Typo.display(d * 0.082))
                    .tracking(-0.5)
                    .foregroundColor(.white.opacity(0.94))
                Rectangle()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: d * 0.16, height: 0.7)
            }
            .offset(x: d * 0.055, y: -d * 0.315)

            Text(labelLine)
                .font(Typo.mono(d * 0.030, .semibold))
                .tracking(1.3)
                .foregroundColor(.white.opacity(0.55))
                .offset(y: d * 0.315)
        }
    }

    private var labelLine: String {
        if let album = song?.album, !album.isEmpty {
            return album.uppercased()
        }
        return "CHERRY CANDY / 006"
    }
}
