import SwiftUI
import UIKit

struct ConditionBadge: View {
    let condition: ToolCondition

    var body: some View {
        Text(condition.rawValue)
            .font(.caption.weight(.bold))
            .foregroundStyle(.black.opacity(0.82))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(condition.badgeColor)
            .clipShape(Capsule())
            .accessibilityLabel("Condition \(condition.rawValue)")
    }
}

struct ToolCard: View {
    let tool: ToolItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(ToolVaultTheme.elevatedBackground)
                Image(systemName: tool.category.iconName)
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(ToolVaultTheme.accentOrange)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(tool.toolName)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    ConditionBadge(condition: tool.currentCondition)
                }

                Text([tool.brand, tool.model].filter { !$0.isEmpty }.joined(separator: " "))
                    .font(.subheadline)
                    .foregroundStyle(ToolVaultTheme.mutedText)
                    .lineLimit(1)

                HStack {
                    Label(tool.category.rawValue, systemImage: "tag.fill")
                    Spacer()
                    Text(tool.estimatedResaleValue.gbpFormatted)
                        .fontWeight(.bold)
                }
                .font(.caption)
                .foregroundStyle(ToolVaultTheme.mutedText)
            }
        }
        .toolVaultCard()
    }
}

struct InventoryValueCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(tint)
                Spacer()
            }
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(ToolVaultTheme.mutedText)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(ToolVaultTheme.mutedText.opacity(0.82))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .toolVaultCard()
    }
}

struct MaintenanceCard: View {
    let record: MaintenanceRecord
    let toolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label(record.maintenanceType.rawValue, systemImage: "wrench.adjustable.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(record.cost.gbpFormatted)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ToolVaultTheme.accentOrange)
            }
            Text(toolName)
                .font(.subheadline)
                .foregroundStyle(ToolVaultTheme.mutedText)
            HStack {
                Text(record.maintenanceDate.toolVaultShortDate)
                if record.reminderEnabled {
                    Text("Reminder")
                }
                if record.recurrence != .none {
                    Text(record.recurrence.rawValue)
                }
            }
            .font(.caption)
            .foregroundStyle(ToolVaultTheme.mutedText.opacity(0.8))
        }
        .toolVaultCard()
    }
}

struct AssignmentCard: View {
    let record: AssignmentRecord
    let toolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label(record.assignedUser, systemImage: "person.crop.circle.badge.checkmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(record.status.rawValue)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.95))
                    .clipShape(Capsule())
                    .foregroundStyle(.black.opacity(0.82))
            }
            Text(toolName)
                .font(.subheadline)
                .foregroundStyle(ToolVaultTheme.mutedText)
            Text("Assigned \(record.assignedDate.toolVaultShortDate)")
                .font(.caption)
                .foregroundStyle(ToolVaultTheme.mutedText.opacity(0.8))
        }
        .toolVaultCard()
    }

    private var statusColor: Color {
        switch record.status {
        case .assigned: return ToolVaultTheme.steelBlue
        case .returned: return ToolVaultTheme.positive
        case .overdue: return ToolVaultTheme.warning
        }
    }
}

struct TheftAlertCard: View {
    let report: TheftReport
    let toolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(toolName, systemImage: "lock.shield.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(report.status.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(ToolVaultTheme.danger)
                    .clipShape(Capsule())
            }
            Text(report.lastKnownLocation.isEmpty ? "No last known location recorded" : report.lastKnownLocation)
                .font(.subheadline)
                .foregroundStyle(ToolVaultTheme.mutedText)
            Text(report.dateReported.toolVaultShortDate)
                .font(.caption)
                .foregroundStyle(ToolVaultTheme.mutedText.opacity(0.82))
        }
        .toolVaultCard()
    }
}

struct AnalyticsChartCard<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: () -> Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(ToolVaultTheme.mutedText)
                }
            }
            content()
                .frame(minHeight: 210)
        }
        .toolVaultCard()
    }
}

struct ReportPreviewView: View {
    let report: InventoryReport
    let onShare: (URL) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.richtext.fill")
                .font(.title2)
                .foregroundStyle(ToolVaultTheme.accentOrange)
                .frame(width: 44, height: 44)
                .background(ToolVaultTheme.elevatedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(report.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text("\(report.reportType.rawValue) - \(report.createdAt.toolVaultShortDate)")
                    .font(.caption)
                    .foregroundStyle(ToolVaultTheme.mutedText)
            }
            Spacer()
            Button {
                onShare(URL(fileURLWithPath: report.pdfLocalURL))
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.headline)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(ToolVaultTheme.accentOrange)
            .accessibilityLabel("Share report")
        }
        .toolVaultCard()
    }
}

struct UpgradeBanner: View {
    let title: String
    let message: String
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "bolt.badge.clock.fill")
                .font(.title2)
                .foregroundStyle(ToolVaultTheme.accentOrange)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(ToolVaultTheme.mutedText)
            }
            Spacer()
            Button("Upgrade", action: action)
                .font(.caption.weight(.bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ToolVaultTheme.accentOrange)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .toolVaultCard()
    }
}

struct PhotoThumbnail: View {
    let data: Data

    var body: some View {
        if let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 78, height: 78)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(ToolVaultTheme.elevatedBackground)
                .frame(width: 78, height: 78)
                .overlay(Image(systemName: "photo").foregroundStyle(ToolVaultTheme.mutedText))
        }
    }
}
