import SwiftUI

extension Color {
    // Brand Primary - Teal (matches web design tokens)
    static let appPrimary = Color(hex: "00ACC1")        // Teal - main brand
    static let appPrimaryDark = Color(hex: "00838F")    // Teal darker - headings, links
    static let appPrimaryDarker = Color(hex: "006064")  // Teal darkest - hover states
    static let appAccent = Color(hex: "FF6F00")         // Orange - accents, CTAs
    static let appAccentLight = Color(hex: "FF8F00")    // Orange lighter

    // Cyan Palette (brand tints)
    static let cyan50 = Color(hex: "E0F7FA")
    static let cyan100 = Color(hex: "B2EBF2")
    static let cyan200 = Color(hex: "80DEEA")
    static let cyan700 = Color(hex: "0097A7")
    static let cyan800 = Color(hex: "00838F")
    static let cyan900 = Color(hex: "006064")

    // Semantic colors
    static let appSuccess = Color(hex: "22C55E")   // Green - verified, success
    static let appWarning = Color(hex: "EAB308")   // Yellow - caution
    static let appDanger = Color(hex: "EF4444")    // Red - error, stale
    static let appInfo = Color(hex: "3B82F6")      // Blue - information

    // Light theme colors
    static let lightBackground = Color(hex: "F9FAFB")
    static let lightSurface = Color.white
    static let lightSurfaceAlt = Color(hex: "F9FAFB")
    static let lightCard = Color.white
    static let lightText = Color(hex: "24292E")
    static let lightTextSecondary = Color(hex: "586069")
    static let lightTextMuted = Color(hex: "6B7280")
    static let lightTextHeading = Color(hex: "00838F")
    static let lightBorder = Color(hex: "E1E4E8")
    static let lightBorderLight = Color(hex: "B2EBF2")
    static let lightHover = Color(hex: "E0F7FA")

    // Light Neutral Palette
    static let lightNeutral50 = Color(hex: "F9FAFB")
    static let lightNeutral100 = Color(hex: "F3F4F6")
    static let lightNeutral200 = Color(hex: "E5E7EB")
    static let lightNeutral300 = Color(hex: "D1D5DB")
    static let lightNeutral400 = Color(hex: "9CA3AF")

    // Dark theme colors
    static let darkBackground = Color(hex: "0D1117")
    static let darkSurface = Color(hex: "161B22")
    static let darkSurfaceAlt = Color(hex: "1C2128")
    static let darkCard = Color(hex: "1C2128")
    static let darkText = Color(hex: "E8EEF5")
    static let darkTextSecondary = Color(hex: "8B949E")
    static let darkTextMuted = Color(hex: "6E7681")
    static let darkTextHeading = Color(hex: "79D8EB")
    static let darkBorder = Color(hex: "30363D")
    static let darkBorderLight = Color(hex: "1B3A3A")
    static let darkHover = Color(hex: "1B3A3A")

    // Dark Neutral Palette
    static let darkNeutral50 = Color(hex: "21262D")
    static let darkNeutral100 = Color(hex: "30363D")
    static let darkNeutral200 = Color(hex: "484F58")
    static let darkNeutral300 = Color(hex: "6E7681")
    static let darkNeutral400 = Color(hex: "8B949E")

    // Focus Ring
    static let focusRing = Color(hex: "2563EB")

    // Legacy aliases for backwards compatibility
    static let appPrimaryLight = cyan200

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme-aware colors

extension ShapeStyle where Self == Color {
    static var cardBackground: Color {
        Color(.systemBackground)
    }

    static var secondaryText: Color {
        Color.secondary
    }
}

// MARK: - Category Colors

extension Color {
    /// Get category-specific color
    static func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "food", "food assistance":
            return Color(hex: "FF6F00") // Orange
        case "health", "healthcare", "medical":
            return Color(hex: "EF4444") // Red
        case "recreation", "activities", "entertainment":
            return Color(hex: "8B5CF6") // Purple
        case "community", "community services", "social services":
            return Color(hex: "10B981") // Green
        case "education", "learning", "training":
            return Color(hex: "3B82F6") // Blue
        case "finance", "financial", "financial assistance":
            return Color(hex: "22C55E") // Green
        case "transportation", "transit":
            return Color(hex: "0EA5E9") // Sky blue
        case "technology", "tech", "internet":
            return Color(hex: "6366F1") // Indigo
        case "legal", "legal aid":
            return Color(hex: "64748B") // Slate
        case "housing", "shelter":
            return Color(hex: "F59E0B") // Amber
        case "employment", "jobs", "career":
            return Color(hex: "0891B2") // Cyan
        default:
            return .appPrimary // Teal
        }
    }
}
