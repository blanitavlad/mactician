import SwiftUI

enum LauncherTheme {
    enum ColorToken {
        static let window = Color(red: 0.006, green: 0.012, blue: 0.024)
        static let surface = Color(red: 0.018, green: 0.035, blue: 0.065)
        static let elevatedSurface = Color(red: 0.035, green: 0.065, blue: 0.105)
        static let raisedControl = Color(red: 0.055, green: 0.082, blue: 0.12)
        static let textPrimary = Color.white
        static let textSecondary = Color(red: 0.64, green: 0.69, blue: 0.75)
        static let textTertiary = Color(red: 0.48, green: 0.56, blue: 0.65)
        static let primaryAction = Color(red: 0.29, green: 0.96, blue: 0.58)
        static let interactive = Color(red: 0.69, green: 0.37, blue: 0.98)
        static let success = Color(red: 0.29, green: 0.96, blue: 0.58)
        static let warning = Color(red: 0.78, green: 0.65, blue: 0.36)
        static let danger = Color(red: 0.94, green: 0.3, blue: 0.32)
        static let neutralBorder = Color.white.opacity(0.13)
    }

    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let regular: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
    }

    enum Metric {
        static let outerInset: CGFloat = 16
        static let headerHeight: CGFloat = 56
        static let trafficLightReserve: CGFloat = 56
        static let stateDeckInset: CGFloat = 24
        static let stateDeckPadding: CGFloat = 32
        static let contentMaxWidth: CGFloat = 1120
        static let standardControlHeight: CGFloat = 36
        static let primaryControlHeight: CGFloat = 48
        static let controlRadius: CGFloat = 6
        static let surfaceRadius: CGFloat = 12
        static let sheetWidth: CGFloat = 640
    }
}

extension View {
    func launcherSurface(
        radius: CGFloat = LauncherTheme.Metric.surfaceRadius,
        fill: Color = LauncherTheme.ColorToken.elevatedSurface.opacity(0.96)
    ) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(LauncherTheme.ColorToken.neutralBorder, lineWidth: 1)
        )
    }
}
