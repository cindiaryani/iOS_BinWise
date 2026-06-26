import SwiftUI

enum DS {

    // MARK: – Brand (slate + amber)

    static let brandCharcoal    = Color(hex: "#1C1917")
    static let brandAmber       = Color(hex: "#F59E0B")
    static let brandAmberDeep   = Color(hex: "#D97706")
    static let brandAmberLight  = Color(hex: "#FDE68A")
    static let brandAmberTint   = Color(hex: "#FFFBEB")

    // MARK: – Backgrounds

    static let bgPrimary = Color(hex: "#FAFAF9")
    static let bgWarm    = Color(hex: "#F5F0E8")
    static let bgCard    = Color(hex: "#FFFFFF")
    static let bgDark    = Color(hex: "#292524")

    // MARK: – Text

    static let textPrimary   = Color(hex: "#1C1917")
    static let textSecondary = Color(hex: "#57534E")
    static let textTertiary  = Color(hex: "#A8A29E")
    static let textOnDark    = Color(hex: "#FEF3C7")
    static let textOnAmber   = Color(hex: "#1C1917")

    // MARK: – Borders & dividers

    static let borderLight  = Color(hex: "#E7E5E4")
    static let borderMedium = Color(hex: "#D6D3D1")

    // MARK: – Category colors (functional — unchanged)

    static let categoryRecyclable = Color(hex: "#2563EB")
    static let categoryHazardous  = Color(hex: "#DC2626")
    static let categoryKitchen    = Color(hex: "#16A34A")
    static let categoryOther      = Color(hex: "#6B7280")

    enum Category {
        static let recyclable = DS.categoryRecyclable
        static let hazardous  = DS.categoryHazardous
        static let kitchen    = DS.categoryKitchen
        static let other      = DS.categoryOther
    }

    // MARK: – Status

    static let statusSuccess = Color(hex: "#059669")
    static let statusError   = Color(hex: "#DC2626")
    static let statusWarning = Color(hex: "#F59E0B")

    // MARK: – Gradients

    static let amberGradient = LinearGradient(
        colors: [Color(hex: "#F59E0B"), Color(hex: "#D97706")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let charcoalGradient = LinearGradient(
        colors: [Color(hex: "#1C1917"), Color(hex: "#292524")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // MARK: – Back-compat aliases (old token names → new palette)
    // Kept so existing call sites compile unchanged; new code should prefer the
    // explicit tokens above.

    static let primary       = brandCharcoal
    static let background    = bgPrimary
    static let surface       = bgCard
    static let border        = borderLight
    static let success       = statusSuccess
    static let tealGradient  = amberGradient

    // MARK: – Corner radii

    enum Radius {
        static let card:    CGFloat = 16
        static let control: CGFloat = 14
        static let badge:   CGFloat = 999
    }

    // MARK: – Spacing scale

    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: – Section header helper

    static func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(DS.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: – Unified card style

/// The single card style used everywhere in BinWise: white surface, 16pt corners,
/// soft shadow. Apply via `.cardStyle()`.
struct BinWiseCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DS.bgCard)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 3)
    }
}

/// Legacy name kept as a typealias so existing `BinWiseCardModifier()` references still compile.
typealias BinWiseCardModifier = BinWiseCard

extension View {
    func cardStyle() -> some View {
        modifier(BinWiseCard())
    }

    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 3)
    }

    // MARK: – Unified button styles (Section F)

    /// Full-width primary button: brandCharcoal background, textOnDark text, 52pt tall, 14pt corners.
    func primaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(DS.textOnDark)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(DS.brandCharcoal)
            .cornerRadius(DS.Radius.control)
    }

    /// Full-width secondary button: brandAmberTint background, textPrimary text, 14pt corners.
    func secondaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(DS.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(DS.brandAmberTint)
            .cornerRadius(DS.Radius.control)
    }
}

// MARK: – Color hex init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
