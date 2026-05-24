# GitHub TestFlight Secrets

The signed archive workflow is `.github/workflows/ios-testflight.yml`.

Add these repository secrets in GitHub:

| Secret | Value |
| --- | --- |
| `APPLE_CERTIFICATE_BASE64` | Base64 of an Apple Distribution `.p12` whose certificate is included in `ToolVault_AI_App_Store.mobileprovision`. |
| `APPLE_CERTIFICATE_PASSWORD` | Password used when exporting that `.p12`. |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Contents of `SigningAssets/APPLE_PROVISIONING_PROFILE_BASE64.txt`. |
| `APP_STORE_CONNECT_API_KEY_ID` | `YGUJ392L3K` |
| `APP_STORE_CONNECT_API_ISSUER_ID` | `69a6de76-14b3-47e3-e053-5b8c7c11a4d1` |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Contents of `SigningAssets/APP_STORE_CONNECT_API_KEY_BASE64.txt`. |
| `KEYCHAIN_PASSWORD` | Optional random CI keychain password. If omitted, the workflow uses the GitHub run ID. |

The local `SigningAssets/` folder is ignored by Git and must not be committed.

Known local Apple Distribution `.p12` candidates that match the ToolVault provisioning profile certificates:

- `C:\Users\User\Documents\GardenOps AI\credentials\ios\apple_distribution.p12`
- `C:\Users\User\Documents\PipeBoss AI\Signing\AppleDistribution.p12`
- `C:\Users\User\Documents\QuoteCraft AI\mobile\ios-credentials\distribution.p12`

The workflow can be started from GitHub Actions after the secrets are added. Use `upload_to_testflight=false` to produce a signed IPA artifact only, or `true` to upload it to App Store Connect.
