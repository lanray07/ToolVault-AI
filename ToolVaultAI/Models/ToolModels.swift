import Foundation
import SwiftData

enum TradeType: String, CaseIterable, Identifiable, Codable {
    case electrician = "Electrician"
    case plumber = "Plumber"
    case roofer = "Roofer"
    case landscaper = "Landscaper"
    case mechanic = "Mechanic"
    case contractor = "Contractor"
    case constructionCompany = "Construction Company"
    case mobileTechnician = "Mobile Technician"
    case other = "Other Trade"

    var id: String { rawValue }
}

enum TeamSetup: String, CaseIterable, Identifiable, Codable {
    case solo = "Solo"
    case team = "Team"

    var id: String { rawValue }
}

enum OnboardingGoal: String, CaseIterable, Identifiable, Codable {
    case inventoryTracking = "Inventory Tracking"
    case theftProtection = "Theft Protection"
    case resaleTracking = "Resale Tracking"
    case maintenanceTracking = "Maintenance Tracking"
    case teamManagement = "Team Management"

    var id: String { rawValue }
}

enum ToolCategory: String, CaseIterable, Identifiable, Codable {
    case powerTools = "Power Tools"
    case handTools = "Hand Tools"
    case plumbing = "Plumbing"
    case electrical = "Electrical"
    case roofing = "Roofing"
    case landscaping = "Landscaping"
    case automotive = "Automotive"
    case measuringTools = "Measuring Tools"
    case generators = "Generators"
    case ladders = "Ladders"
    case safetyEquipment = "Safety Equipment"
    case custom = "Custom"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .powerTools: return "drill"
        case .handTools: return "hammer"
        case .plumbing: return "pipe.and.drop"
        case .electrical: return "bolt.fill"
        case .roofing: return "house.fill"
        case .landscaping: return "leaf.fill"
        case .automotive: return "wrench.and.screwdriver.fill"
        case .measuringTools: return "ruler"
        case .generators: return "powerplug.fill"
        case .ladders: return "stairs"
        case .safetyEquipment: return "shield.lefthalf.filled"
        case .custom: return "square.grid.2x2"
        }
    }
}

enum ToolCondition: String, CaseIterable, Identifiable, Codable {
    case new = "New"
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case damaged = "Damaged"
    case missing = "Missing"

    var id: String { rawValue }

    var sortWeight: Int {
        switch self {
        case .new: return 0
        case .excellent: return 1
        case .good: return 2
        case .fair: return 3
        case .poor: return 4
        case .damaged: return 5
        case .missing: return 6
        }
    }
}

enum MaintenanceType: String, CaseIterable, Identifiable, Codable {
    case bladeChange = "Blade Change"
    case servicing = "Servicing"
    case calibration = "Calibration"
    case batteryReplacement = "Battery Replacement"
    case inspection = "Inspection"
    case cleaning = "Cleaning"
    case repair = "Repair"
    case other = "Other"

    var id: String { rawValue }
}

enum MaintenanceRecurrence: String, CaseIterable, Identifiable, Codable {
    case none = "No Repeat"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"

    var id: String { rawValue }
}

enum AssignmentStatus: String, CaseIterable, Identifiable, Codable {
    case assigned = "Assigned"
    case returned = "Returned"
    case overdue = "Overdue"

    var id: String { rawValue }
}

enum TheftReportStatus: String, CaseIterable, Identifiable, Codable {
    case draft = "Draft"
    case missing = "Missing"
    case reported = "Reported"
    case recovered = "Recovered"

    var id: String { rawValue }
}

enum InventoryReportType: String, CaseIterable, Identifiable, Codable {
    case fullInventory = "Full Inventory"
    case highValueAssets = "High-Value Assets"
    case stolenMissingTools = "Stolen or Missing Tools"
    case maintenanceSummary = "Maintenance Summary"
    case insuranceReadyExport = "Insurance-Ready Export"
    case resaleValuationSummary = "Resale Valuation Summary"

    var id: String { rawValue }

    var fileSlug: String {
        rawValue.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
    }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable, Codable {
    case free = "Free"
    case pro = "Pro"
    case business = "Business"

    var id: String { rawValue }

    var toolLimit: Int? {
        switch self {
        case .free: return 25
        case .pro, .business: return nil
        }
    }

    var statusText: String {
        switch self {
        case .free: return "Free plan"
        case .pro: return "Pro active"
        case .business: return "Business active"
        }
    }
}

@Model
final class ToolItem {
    @Attribute(.unique) var id: UUID
    var toolName: String
    var categoryRawValue: String
    var brand: String
    var model: String
    var serialNumber: String
    var purchaseDate: Date
    var purchasePrice: Double
    var conditionRawValue: String
    var estimatedResaleValue: Double
    var storageLocation: String
    var assignedUser: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        toolName: String,
        category: ToolCategory,
        brand: String = "",
        model: String = "",
        serialNumber: String = "",
        purchaseDate: Date = .now,
        purchasePrice: Double = 0,
        currentCondition: ToolCondition = .good,
        estimatedResaleValue: Double = 0,
        storageLocation: String = "",
        assignedUser: String = "",
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.toolName = toolName
        self.categoryRawValue = category.rawValue
        self.brand = brand
        self.model = model
        self.serialNumber = serialNumber
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.conditionRawValue = currentCondition.rawValue
        self.estimatedResaleValue = estimatedResaleValue
        self.storageLocation = storageLocation
        self.assignedUser = assignedUser
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var category: ToolCategory {
        get { ToolCategory(rawValue: categoryRawValue) ?? .custom }
        set { categoryRawValue = newValue.rawValue }
    }

    var currentCondition: ToolCondition {
        get { ToolCondition(rawValue: conditionRawValue) ?? .good }
        set { conditionRawValue = newValue.rawValue }
    }

    var displayName: String {
        [brand, model].filter { !$0.isEmpty }.isEmpty
            ? toolName
            : "\(toolName) - \([brand, model].filter { !$0.isEmpty }.joined(separator: " "))"
    }

    var isHighValue: Bool {
        purchasePrice >= 500 || estimatedResaleValue >= 300
    }

    var needsMaintenanceAttention: Bool {
        currentCondition == .fair || currentCondition == .poor || currentCondition == .damaged
    }

    var depreciationAmount: Double {
        max(purchasePrice - estimatedResaleValue, 0)
    }
}

@Model
final class ToolPhoto {
    @Attribute(.unique) var id: UUID
    var toolId: UUID
    @Attribute(.externalStorage) var imageData: Data?
    var localImageURL: String
    var caption: String
    var createdAt: Date

    init(id: UUID = UUID(), toolId: UUID, imageData: Data? = nil, localImageURL: String = "", caption: String = "", createdAt: Date = .now) {
        self.id = id
        self.toolId = toolId
        self.imageData = imageData
        self.localImageURL = localImageURL
        self.caption = caption
        self.createdAt = createdAt
    }
}

@Model
final class MaintenanceRecord {
    @Attribute(.unique) var id: UUID
    var toolId: UUID
    var maintenanceTypeRawValue: String
    var maintenanceDate: Date
    var cost: Double
    var notes: String
    var recurrenceRawValue: String
    var reminderEnabled: Bool
    var nextDueDate: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        toolId: UUID,
        maintenanceType: MaintenanceType,
        maintenanceDate: Date = .now,
        cost: Double = 0,
        notes: String = "",
        recurrence: MaintenanceRecurrence = .none,
        reminderEnabled: Bool = false,
        nextDueDate: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.toolId = toolId
        self.maintenanceTypeRawValue = maintenanceType.rawValue
        self.maintenanceDate = maintenanceDate
        self.cost = cost
        self.notes = notes
        self.recurrenceRawValue = recurrence.rawValue
        self.reminderEnabled = reminderEnabled
        self.nextDueDate = nextDueDate
        self.createdAt = createdAt
    }

    var maintenanceType: MaintenanceType {
        get { MaintenanceType(rawValue: maintenanceTypeRawValue) ?? .other }
        set { maintenanceTypeRawValue = newValue.rawValue }
    }

    var recurrence: MaintenanceRecurrence {
        get { MaintenanceRecurrence(rawValue: recurrenceRawValue) ?? .none }
        set { recurrenceRawValue = newValue.rawValue }
    }
}

@Model
final class AssignmentRecord {
    @Attribute(.unique) var id: UUID
    var toolId: UUID
    var assignedUser: String
    var assignedDate: Date
    var returnedDate: Date?
    var statusRawValue: String
    var notes: String

    init(
        id: UUID = UUID(),
        toolId: UUID,
        assignedUser: String,
        assignedDate: Date = .now,
        returnedDate: Date? = nil,
        status: AssignmentStatus = .assigned,
        notes: String = ""
    ) {
        self.id = id
        self.toolId = toolId
        self.assignedUser = assignedUser
        self.assignedDate = assignedDate
        self.returnedDate = returnedDate
        self.statusRawValue = status.rawValue
        self.notes = notes
    }

    var status: AssignmentStatus {
        get { AssignmentStatus(rawValue: statusRawValue) ?? .assigned }
        set { statusRawValue = newValue.rawValue }
    }
}

@Model
final class TheftReport {
    @Attribute(.unique) var id: UUID
    var toolId: UUID
    var dateReported: Date
    var reportNotes: String
    var lastKnownLocation: String
    var statusRawValue: String

    init(
        id: UUID = UUID(),
        toolId: UUID,
        dateReported: Date = .now,
        reportNotes: String = "",
        lastKnownLocation: String = "",
        status: TheftReportStatus = .missing
    ) {
        self.id = id
        self.toolId = toolId
        self.dateReported = dateReported
        self.reportNotes = reportNotes
        self.lastKnownLocation = lastKnownLocation
        self.statusRawValue = status.rawValue
    }

    var status: TheftReportStatus {
        get { TheftReportStatus(rawValue: statusRawValue) ?? .missing }
        set { statusRawValue = newValue.rawValue }
    }
}

@Model
final class InventoryReport {
    @Attribute(.unique) var id: UUID
    var title: String
    var reportTypeRawValue: String
    var pdfLocalURL: String
    var createdAt: Date

    init(id: UUID = UUID(), title: String, reportType: InventoryReportType, pdfLocalURL: String, createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.reportTypeRawValue = reportType.rawValue
        self.pdfLocalURL = pdfLocalURL
        self.createdAt = createdAt
    }

    var reportType: InventoryReportType {
        get { InventoryReportType(rawValue: reportTypeRawValue) ?? .fullInventory }
        set { reportTypeRawValue = newValue.rawValue }
    }
}

@Model
final class SubscriptionState {
    @Attribute(.unique) var id: UUID
    var planRawValue: String
    var isActive: Bool
    var renewsAt: Date?

    init(id: UUID = UUID(), plan: SubscriptionPlan = .free, isActive: Bool = false, renewsAt: Date? = nil) {
        self.id = id
        self.planRawValue = plan.rawValue
        self.isActive = isActive
        self.renewsAt = renewsAt
    }

    var plan: SubscriptionPlan {
        get { SubscriptionPlan(rawValue: planRawValue) ?? .free }
        set { planRawValue = newValue.rawValue }
    }
}

@Model
final class ValueHistoryRecord {
    @Attribute(.unique) var id: UUID
    var toolId: UUID
    var estimatedValue: Double
    var conditionRawValue: String
    var note: String
    var recordedAt: Date

    init(id: UUID = UUID(), toolId: UUID, estimatedValue: Double, condition: ToolCondition, note: String = "", recordedAt: Date = .now) {
        self.id = id
        self.toolId = toolId
        self.estimatedValue = estimatedValue
        self.conditionRawValue = condition.rawValue
        self.note = note
        self.recordedAt = recordedAt
    }

    var condition: ToolCondition {
        get { ToolCondition(rawValue: conditionRawValue) ?? .good }
        set { conditionRawValue = newValue.rawValue }
    }
}

extension Double {
    var gbpFormatted: String {
        formatted(.currency(code: "GBP"))
    }
}

extension Date {
    var toolVaultShortDate: String {
        formatted(date: .abbreviated, time: .omitted)
    }
}
