import SwiftUI

public enum Theme {
    public enum ColorToken {
        public static let textDark = Color(red: 0.36, green: 0.36, blue: 0.36)
        public static let textSecondary = Color(red: 0.56, green: 0.56, blue: 0.58)
        public static let primary = Color(red: 0.00, green: 0.52, blue: 0.58)
        public static let accent = Color(red: 1.00, green: 0.54, blue: 0.00)
        public static let tabActive = Color(red: 0.65, green: 0.32, blue: 0.20)
        public static let cardStroke = Color(.sRGBLinear, white: 0.85, opacity: 1.0)
        public static let cardFill = Color.white.opacity(0.85)
    }
    public enum GradientToken {
        public static let vibrant = LinearGradient(
            colors: [Color(red: 0.53, green: 0.81, blue: 0.92),
                     Color(red: 0.00, green: 0.77, blue: 0.80)],
            startPoint: .top, endPoint: .bottom
        )
    }
    public enum Typography {
        public static func heading(_ size: CGFloat = 32) -> Font { .system(size: size, weight: .bold, design: .rounded) }
        public static func body(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .regular, design: .default) }
        public static func label(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    }
    public enum Spacing {
        public static let xs: CGFloat = 4, sm: CGFloat = 8, md: CGFloat = 12,
                           lg: CGFloat = 16, xl: CGFloat = 24, xxl: CGFloat = 32
    }
}
