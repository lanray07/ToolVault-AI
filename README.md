# ToolVault AI

ToolVault AI is a SwiftUI and SwiftData iOS app scaffold for tool inventory, condition tracking, theft protection, maintenance reminders, team assignment, PDF reporting, and resale value management.

## Open in Xcode

Open `ToolVaultAI.xcodeproj`, select the `ToolVaultAI` scheme, and run on an iOS 17+ simulator or device.

## Included

- SwiftUI `NavigationStack` and tab architecture
- SwiftData local persistence
- MVVM view models
- Mock AI enabled by default
- Remote AI service placeholder using `POST https://YOUR_BACKEND_URL.com/toolvault-ai`
- StoreKit 2 subscription scaffolding
- PhotosPicker and camera capture support
- PDF report generation and native share sheet
- Local notification scheduling for maintenance reminders
- Swift Charts analytics
- QR and NFC placeholder service architecture

## Before Release

- Replace the backend URL and route AI calls through a server. Do not store API keys in the app.
- Configure StoreKit products in App Store Connect and/or an official Xcode StoreKit configuration.
- Replace placeholder Privacy Policy, Terms of Use, QR, NFC, multi-user, custom branding, and bulk import flows.
- Add app icons, launch assets, and production signing settings.
