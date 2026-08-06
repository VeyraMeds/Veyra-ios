# VEYRA iOS App

A native iOS WebView wrapper for the VEYRA Health PWA at https://veyrameds.com.

## Build Requirements

- Xcode 15+ (or use GitHub Actions macOS runner)
- iOS 15.0+ deployment target
- Apple Developer account (Individual or Organization)
- No CocoaPods or external dependencies required

## Building with GitHub Actions (No Mac Required)

1. Push this repo to GitHub
2. Add the following repository secrets:
   - `APPLE_TEAM_ID` — Your Apple Developer Team ID (found in App Store Connect → Account)
   - `BUILD_CERTIFICATE_BASE64` — Your distribution certificate (.p12) base64 encoded
   - `P12_PASSWORD` — Password for the .p12 certificate
   - `BUILD_PROVISION_PROFILE_BASE64` — Your App Store provisioning profile base64 encoded
   - `KEYCHAIN_PASSWORD` — Any random password for the temporary keychain
3. Run the workflow
4. Download the IPA artifact from the Actions tab
5. Upload to App Store Connect using Transporter or the App Store Connect API

## Building Locally with Xcode

1. Open `VEYRA.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Select a simulator or connected device
4. Build and run (Cmd+R)

## App Configuration

- Bundle ID: `com.veyrameds.app`
- Display Name: VEYRA
- URL: https://veyrameds.com
- Orientation: Portrait (portrait + landscape on iPad)
- iOS minimum: 15.0
- Camera permission: Yes (profile photos)
- Photo library permission: Yes (profile/progress photos)
