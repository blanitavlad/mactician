import SwiftUI

struct LauncherTelemetryNoticeView: View {
    @ObservedObject var model: LauncherModel
    @State private var extendedDiagnostics = false

    var body: some View {
        VStack(alignment: .leading, spacing: LauncherTheme.Spacing.large) {
            VStack(alignment: .leading, spacing: LauncherTheme.Spacing.small) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(LauncherTheme.ColorToken.interactive)
                    .accessibilityHidden(true)
                Text(LauncherL10n.text("telemetry.notice.title"))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(LauncherTheme.ColorToken.textPrimary)
            }

            Text(LauncherL10n.text("telemetry.notice.body"))
                .font(.system(size: 13))
                .foregroundColor(LauncherTheme.ColorToken.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(
                LauncherL10n.text("telemetry.extended.toggle"),
                isOn: $extendedDiagnostics
            )
            .toggleStyle(.checkbox)
            .font(.system(size: 13, weight: .medium))

            Spacer()

            HStack(spacing: LauncherTheme.Spacing.regular) {
                Link(
                    LauncherL10n.text("telemetry.privacy_policy"),
                    destination: MacticianIdentity.privacyPolicyURL
                )
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(LauncherTheme.ColorToken.interactive)
                Spacer()
                Button(LauncherL10n.text("telemetry.continue")) {
                    model.completeTelemetryNotice(
                        extendedDiagnostics: extendedDiagnostics
                    )
                }
                .buttonStyle(LauncherPrimaryButtonStyle())
            }
        }
        .padding(LauncherTheme.Spacing.xLarge)
        .frame(width: 580, height: 390)
        .background(LauncherTheme.ColorToken.surface)
        .preferredColorScheme(.dark)
    }
}
