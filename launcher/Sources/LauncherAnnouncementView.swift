import SwiftUI

struct LauncherAnnouncementView: View {
    let announcement: LauncherAnnouncement
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let image = announcement.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Text(announcement.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(LauncherTheme.ColorToken.textPrimary)

            ScrollView {
                Text(announcement.text)
                    .font(.system(size: 15))
                    .foregroundStyle(LauncherTheme.ColorToken.textSecondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 240)

            HStack {
                Spacer()
                Button(LauncherL10n.text("action.close"), action: dismiss)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 600)
        .background(LauncherTheme.ColorToken.surface)
    }
}
