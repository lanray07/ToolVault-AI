import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case inventory = "Inventory"
    case maintenance = "Maintenance"
    case reports = "Reports"
    case analytics = "Analytics"
    case settings = "Settings"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.67percent"
        case .inventory: return "shippingbox.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .reports: return "doc.text.fill"
        case .analytics: return "chart.xyaxis.line"
        case .settings: return "gearshape.fill"
        }
    }
}

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            AppShellView()
        } else {
            OnboardingView {
                withAnimation(.snappy) {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}

struct AppShellView: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var notifications: NotificationService
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label(AppTab.dashboard.rawValue, systemImage: AppTab.dashboard.iconName) }
            .tag(AppTab.dashboard)

            NavigationStack {
                InventoryListView()
            }
            .tabItem { Label(AppTab.inventory.rawValue, systemImage: AppTab.inventory.iconName) }
            .tag(AppTab.inventory)

            NavigationStack {
                MaintenanceTrackerView()
            }
            .tabItem { Label(AppTab.maintenance.rawValue, systemImage: AppTab.maintenance.iconName) }
            .tag(AppTab.maintenance)

            NavigationStack {
                InventoryReportsView()
            }
            .tabItem { Label(AppTab.reports.rawValue, systemImage: AppTab.reports.iconName) }
            .tag(AppTab.reports)

            NavigationStack {
                AnalyticsDashboardView()
            }
            .tabItem { Label(AppTab.analytics.rawValue, systemImage: AppTab.analytics.iconName) }
            .tag(AppTab.analytics)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label(AppTab.settings.rawValue, systemImage: AppTab.settings.iconName) }
            .tag(AppTab.settings)
        }
        .tint(ToolVaultTheme.accentOrange)
        .task {
            subscriptions.start()
            await subscriptions.loadProducts()
            await notifications.refreshAuthorizationStatus()
        }
    }
}
