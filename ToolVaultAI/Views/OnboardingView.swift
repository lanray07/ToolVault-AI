import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @AppStorage("tradeType") private var storedTradeType = TradeType.electrician.rawValue
    @AppStorage("teamSetup") private var storedTeamSetup = TeamSetup.solo.rawValue
    @AppStorage("approximateToolCount") private var storedToolCount = "25"
    @AppStorage("mainGoal") private var storedMainGoal = OnboardingGoal.inventoryTracking.rawValue

    @State private var tradeType: TradeType = .electrician
    @State private var teamSetup: TeamSetup = .solo
    @State private var approximateToolCount = "25"
    @State private var mainGoal: OnboardingGoal = .inventoryTracking

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("ToolVault AI")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Inventory, condition tracking, theft protection, and resale intelligence for working tools.")
                        .font(.title3)
                        .foregroundStyle(ToolVaultTheme.mutedText)
                }
                .padding(.top, 36)

                VStack(spacing: 16) {
                    pickerField("Trade or business type", selection: $tradeType, values: TradeType.allCases)
                    pickerField("Solo or team", selection: $teamSetup, values: TeamSetup.allCases)

                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel(title: "Approximate tool count")
                        TextField("25", text: $approximateToolCount)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(ToolVaultTheme.elevatedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .foregroundStyle(.white)
                    }

                    pickerField("Main goal", selection: $mainGoal, values: OnboardingGoal.allCases)
                }
                .toolVaultCard()

                DisclaimerBox()

                Button {
                    storedTradeType = tradeType.rawValue
                    storedTeamSetup = teamSetup.rawValue
                    storedToolCount = approximateToolCount
                    storedMainGoal = mainGoal.rawValue
                    onComplete()
                } label: {
                    Label("Start Tracking Tools", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(ToolVaultPrimaryButtonStyle())
            }
            .padding()
        }
        .toolVaultScreenBackground()
        .onAppear {
            tradeType = TradeType(rawValue: storedTradeType) ?? .electrician
            teamSetup = TeamSetup(rawValue: storedTeamSetup) ?? .solo
            approximateToolCount = storedToolCount
            mainGoal = OnboardingGoal(rawValue: storedMainGoal) ?? .inventoryTracking
        }
    }

    private func pickerField<T: Identifiable & Hashable & RawRepresentable>(_ title: String, selection: Binding<T>, values: [T]) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: title)
            Picker(title, selection: selection) {
                ForEach(values) { value in
                    Text(value.rawValue).tag(value)
                }
            }
            .pickerStyle(.menu)
            .tint(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(ToolVaultTheme.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}
