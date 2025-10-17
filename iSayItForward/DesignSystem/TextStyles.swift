import SwiftUI

// MARK: - Kodchasan Font Family
extension Font {
    struct Kodchasan {
        static func regular(_ size: CGFloat) -> Font {
            .custom("Kodchasan-Regular", size: size)
        }
        static func medium(_ size: CGFloat) -> Font {
            .custom("Kodchasan-Medium", size: size)
        }
        static func semiBold(_ size: CGFloat) -> Font {
            .custom("Kodchasan-SemiBold", size: size)
        }
        static func bold(_ size: CGFloat) -> Font {
            .custom("Kodchasan-Bold", size: size)
        }
    }
}

// MARK: - Global Text Styles
struct TextStyles {
    // Titles
    static func title(_ size: CGFloat = 42) -> Font {
        .Kodchasan.bold(size)
    }

    static func appTitle(_ size: CGFloat = 28) -> Font {
        .Kodchasan.bold(size)
    }

    static func subtitle(_ size: CGFloat = 18) -> Font {
        .Kodchasan.semiBold(size)
    }

    static func cardTitle(_ size: CGFloat = 20) -> Font {
        .Kodchasan.semiBold(size)
    }

    // Body
    static func body(_ size: CGFloat = 15) -> Font {
        .Kodchasan.regular(size)
    }

    static func small(_ size: CGFloat = 12) -> Font {
        .Kodchasan.regular(size)
    }

    // Utility
    static var sectionTitle: Font {
        .Kodchasan.semiBold(18)
    }

    static var caption: Font {
        .Kodchasan.medium(13)
    }

    static var label: Font {
        .Kodchasan.semiBold(14)
    }
}
