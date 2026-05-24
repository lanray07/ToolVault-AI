import SwiftUI

enum ToolVaultTheme {
    static let background = Color(red: 0.045, green: 0.052, blue: 0.060)
    static let elevatedBackground = Color(red: 0.085, green: 0.095, blue: 0.110)
    static let surface = Color(red: 0.115, green: 0.130, blue: 0.150)
    static let surfaceLight = Color(red: 0.155, green: 0.175, blue: 0.200)
    static let accentOrange = Color(red: 0.98, green: 0.42, blue: 0.08)
    static let steelBlue = Color(red: 0.22, green: 0.46, blue: 0.62)
    static let mutedText = Color.white.opacity(0.64)
    static let border = Color.white.opacity(0.10)
    static let positive = Color(red: 0.25, green: 0.78, blue: 0.48)
    static let warning = Color(red: 1.0, green: 0.74, blue: 0.24)
    static let danger = Color(red: 0.95, green: 0.22, blue: 0.18)
}

extension View {
    func toolVaultScreenBackground() -> some View {
        background(ToolVaultTheme.background.ignoresSafeArea())
    }

    func toolVaultCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(ToolVaultTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(ToolVaultTheme.border, lineWidth: 1)
                    )
            )
    }
}

extension ToolCondition {
    var badgeColor: Color {
        switch self {
        case .new, .excellent:
            return ToolVaultTheme.positive
        case .good:
            return ToolVaultTheme.steelBlue
        case .fair:
            return ToolVaultTheme.warning
        case .poor, .damaged:
            return ToolVaultTheme.danger
        case .missing:
            return .gray
        }
    }
}

struct ToolVaultHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(ToolVaultTheme.mutedText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionTitle: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ToolVaultTheme.accentOrange)
            }
        }
    }
}
