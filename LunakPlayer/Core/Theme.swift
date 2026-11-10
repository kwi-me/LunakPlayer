import SwiftUI
import UIKit

// MARK: - Color helpers

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - Palette
// Sampled from the reference artwork: cold paper grey, ink navy, signal blue.

enum Ink {
    static let paper       = Color(hex: 0xE7EAEE)
    static let paperLight  = Color(hex: 0xF2F4F6)
    static let panel       = Color(hex: 0xF8F9FB)
    static let panelInset  = Color(hex: 0xE4EAF4)
    static let line        = Color(hex: 0xB2B9C4)
    static let hairline    = Color(hex: 0x8B93A1)
    static let navy        = Color(hex: 0x101E3E)
    static let blue        = Color(hex: 0x1B3FA8)
    static let blueBright  = Color(hex: 0x2A57D6)
    static let blueDeep    = Color(hex: 0x122C63)
    static let card        = Color(hex: 0x16346F)
    static let cardDeep    = Color(hex: 0x0D2450)
    static let mist        = Color(hex: 0x9AAACA)
}

// MARK: - Typography

enum Typo {
    /// Helvetica Neue Condensed Black ships with iOS; it is the closest match
    /// to the tightly-set compressed headline in the reference.
    static func display(_ size: CGFloat) -> Font {
        if UIFont(name: "HelveticaNeue-CondensedBlack", size: size) != nil {
            return .custom("HelveticaNeue-CondensedBlack", size: size)
        }
        return .system(size: size, weight: .black)
    }

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Small shared primitives

/// Tiny uppercase, wide-tracked mono caption used all over the chassis.
struct MonoText: View {
    var text: String
    var size: CGFloat = 7
    var weight: Font.Weight = .medium
    var color: Color = Ink.hairline
    var tracking: CGFloat = 0.9

    var body: some View {
        Text(text.uppercased())
            .font(Typo.mono(size, weight))
            .tracking(tracking)
            .foregroundColor(color)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }
}

/// Compressed display headline.
struct DisplayText: View {
    var text: String
    var size: CGFloat
    var color: Color
    var italic: Bool = false

    var body: some View {
        Text(text.uppercased())
            .font(Typo.display(size))
            .italic(italic)
            .tracking(-1.0)
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.35)
    }
}

/// Fake barcode rhythm at the bottom of hardware panels.
struct BarcodeView: View {
    var width: CGFloat = 42
    var height: CGFloat = 9
    var color: Color = Ink.hairline

    private let pattern: [CGFloat] = [1, 1, 2, 1, 1, 3, 1, 2, 1, 1, 1, 2, 3, 1, 1, 2, 1, 1, 3, 1, 2, 1, 1]

    var body: some View {
        HStack(alignment: .center, spacing: 1) {
            ForEach(pattern.indices, id: \.self) { i in
                Rectangle()
                    .fill(color.opacity(0.8))
                    .frame(width: pattern[i])
            }
        }
        .frame(width: width, height: height, alignment: .leading)
        .clipped()
    }
}

/// Four-point sparkle used as a graphic punctuation mark.
struct Sparkle: View {
    var size: CGFloat = 12
    var color: Color = Ink.navy

    var body: some View {
        Canvas { ctx, s in
            let w = s.width
            let h = s.height
            var path = Path()
            path.move(to: CGPoint(x: w * 0.5, y: 0))
            path.addQuadCurve(to: CGPoint(x: w, y: h * 0.5), control: CGPoint(x: w * 0.56, y: h * 0.44))
            path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h), control: CGPoint(x: w * 0.56, y: h * 0.56))
            path.addQuadCurve(to: CGPoint(x: 0, y: h * 0.5), control: CGPoint(x: w * 0.44, y: h * 0.56))
            path.addQuadCurve(to: CGPoint(x: w * 0.5, y: 0), control: CGPoint(x: w * 0.44, y: h * 0.44))
            ctx.fill(path, with: .color(color))
        }
        .frame(width: size, height: size)
    }
}

struct DashedRule: View {
    var color: Color = .white
    var opacity: Double = 0.35
    var dash: [CGFloat] = [2, 3]

    var body: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
            }
            .stroke(color.opacity(opacity), style: StrokeStyle(lineWidth: 1, dash: dash))
        }
        .frame(height: 2)
    }
}

/// Fine engineering grid, drawn once into a Canvas.
struct GridTexture: View {
    var spacing: CGFloat = 9
    var color: Color = .white
    var opacity: Double = 0.06

    var body: some View {
        Canvas { ctx, size in
            var path = Path()
            var x: CGFloat = 0
            while x < size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            var y: CGFloat = 0
            while y < size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            ctx.stroke(path, with: .color(color.opacity(opacity)), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Formatting

func timecode(_ value: Double) -> String {
    guard value.isFinite, value > 0 else { return "00:00" }
    let total = Int(value.rounded())
    let m = total / 60
    let s = total % 60
    return String(format: "%02d:%02d", m, s)
}
