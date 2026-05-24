import SwiftUI

struct LoadingStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(ToolVaultTheme.accentOrange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(ToolVaultTheme.mutedText)
        }
        .frame(maxWidth: .infinity)
        .toolVaultCard()
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(ToolVaultTheme.accentOrange)
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(ToolVaultTheme.mutedText)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(ToolVaultPrimaryButtonStyle())
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .toolVaultCard()
    }
}

struct ErrorStateView: View {
    let message: String
    let retry: (() -> Void)?

    init(message: String, retry: (() -> Void)? = nil) {
        self.message = message
        self.retry = retry
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Something needs attention", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(ToolVaultTheme.warning)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(ToolVaultTheme.mutedText)
            if let retry {
                Button("Try Again", action: retry)
                    .buttonStyle(ToolVaultSecondaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .toolVaultCard()
    }
}

struct ToolVaultPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(ToolVaultTheme.accentOrange.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct ToolVaultSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(ToolVaultTheme.surfaceLight.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(ToolVaultTheme.border, lineWidth: 1)
            )
    }
}

struct FieldLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(ToolVaultTheme.mutedText)
            .textCase(.uppercase)
    }
}

struct InfoLine: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            FieldLabel(title: title)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SimpleTextField: View {
    let title: String
    @Binding var text: String
    let prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: title)
            TextField(prompt, text: $text)
                .foregroundStyle(.white)
                .padding(12)
                .background(ToolVaultTheme.elevatedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

struct DisclaimerBox: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("AI estimate disclaimer", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(ToolVaultTheme.accentOrange)
            Text("AI estimates are informational only. They are not insurance valuations, resale values may vary, and users should verify all values independently.")
                .font(.footnote)
                .foregroundStyle(ToolVaultTheme.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .toolVaultCard()
    }
}
