# Apple Developer Portal Setup Guide

This guide walks through registering Bay Navigator in Apple Developer Portal for App Store and TestFlight distribution.

## Prerequisites

- Apple Developer Program membership ($99/year) at [developer.apple.com](https://developer.apple.com)
- Access to the Save the Shores, Inc. developer account (Team ID: `C5U8Z5536K`)
- Xcode installed on your Mac

## 1. Register App Identifiers

Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list)

### iOS App Identifier

1. Click **"+"** to register a new identifier
2. Select **"App IDs"** → Continue
3. Select **"App"** → Continue
4. Fill in:
   - **Description**: `Bay Navigator iOS`
   - **Bundle ID**: Select "Explicit" and enter `org.baytides.navigator`
5. Enable Capabilities:
   - ✅ App Groups (for widget/extension data sharing)
   - ✅ Associated Domains (for deep linking)
   - ✅ Push Notifications (optional, for future updates)
   - ✅ Siri (for voice commands)
6. Click **Register**

### macOS App Identifier

1. Click **"+"** to register a new identifier
2. Select **"App IDs"** → Continue
3. Select **"App"** → Continue
4. Fill in:
   - **Description**: `Bay Navigator macOS`
   - **Bundle ID**: Select "Explicit" and enter `org.baytides.navigator.macos`
5. Enable Capabilities:
   - ✅ App Groups
   - ✅ Associated Domains
6. Click **Register**

### visionOS App Identifier

1. Click **"+"** to register a new identifier
2. Select **"App IDs"** → Continue
3. Select **"App"** → Continue
4. Fill in:
   - **Description**: `Bay Navigator visionOS`
   - **Bundle ID**: Select "Explicit" and enter `org.baytides.navigator.visionos`
5. Enable Capabilities:
   - ✅ App Groups
6. Click **Register**

### Note on MapKit

The app uses Apple's native MapKit for maps. **No Maps ID or API key is required** - MapKit is free and included with all Apple platforms. This is different from Google Maps or Mapbox which require API keys.

### App Group Identifier (for data sharing between app and extensions)

1. Click **"+"** to register a new identifier
2. Select **"App Groups"** → Continue
3. Fill in:
   - **Description**: `Bay Navigator Shared`
   - **Identifier**: `group.org.baytides.navigator`
4. Click **Register**

## 2. Create Certificates

Go to [Certificates](https://developer.apple.com/account/resources/certificates/list)

### Distribution Certificate (for App Store)

1. Click **"+"** to create a new certificate
2. Select **"Apple Distribution"** → Continue
3. Follow the instructions to create a Certificate Signing Request (CSR):
   - Open **Keychain Access** on your Mac
   - Go to **Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority**
   - Enter your email and name
   - Select **"Saved to disk"**
   - Save the `.certSigningRequest` file
4. Upload the CSR file
5. Download the certificate (`.cer` file)
6. Double-click to install in Keychain

### Export Certificate for GitHub Actions

1. Open **Keychain Access**
2. Find the certificate under "My Certificates" (look for "Apple Distribution: Save the Shores")
3. Right-click → **Export**
4. Save as `.p12` file with a strong password
5. Base64 encode for GitHub secrets:
   ```bash
   base64 -i Certificates.p12 | pbcopy
   ```
6. Add to GitHub repository secrets as `IOS_CERTIFICATE_BASE64`
7. Add the password as `IOS_CERTIFICATE_PASSWORD`

## 3. Create Provisioning Profiles

Go to [Profiles](https://developer.apple.com/account/resources/profiles/list)

### iOS App Store Profile

1. Click **"+"** to create a new profile
2. Select **"App Store Connect"** under Distribution → Continue
3. Select the App ID: `org.baytides.navigator` → Continue
4. Select your Distribution Certificate → Continue
5. Name it: `Bay Navigator iOS App Store`
6. Download and double-click to install

### macOS App Store Profile

1. Click **"+"** to create a new profile
2. Select **"Mac App Store Connect"** under Distribution → Continue
3. Select the App ID: `org.baytides.navigator.macos` → Continue
4. Select your Distribution Certificate → Continue
5. Name it: `Bay Navigator macOS App Store`
6. Download and install

### visionOS App Store Profile

1. Click **"+"** to create a new profile
2. Select **"App Store Connect"** under Distribution → Continue
3. Select the App ID: `org.baytides.navigator.visionos` → Continue
4. Select your Distribution Certificate → Continue
5. Name it: `Bay Navigator visionOS App Store`
6. Download and install

### Export Provisioning Profiles for GitHub Actions

```bash
# iOS
base64 -i ~/Library/MobileDevice/Provisioning\ Profiles/[iOS-PROFILE-UUID].mobileprovision | pbcopy
# Add to GitHub as IOS_PROVISIONING_PROFILE_BASE64

# macOS
base64 -i ~/Library/MobileDevice/Provisioning\ Profiles/[MACOS-PROFILE-UUID].mobileprovision | pbcopy
# Add to GitHub as MACOS_PROVISIONING_PROFILE_BASE64

# visionOS
base64 -i ~/Library/MobileDevice/Provisioning\ Profiles/[VISIONOS-PROFILE-UUID].mobileprovision | pbcopy
# Add to GitHub as VISIONOS_PROVISIONING_PROFILE_BASE64
```

## 4. Create App in App Store Connect

Go to [App Store Connect](https://appstoreconnect.apple.com)

### Create New App

1. Click **"+"** → **"New App"**
2. Fill in:
   - **Platforms**: iOS, macOS (separate apps for each)
   - **Name**: `Bay Navigator`
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select `org.baytides.navigator`
   - **SKU**: `baynavigator-ios` (unique identifier, can be anything)
   - **User Access**: Full Access
3. Click **Create**

Repeat for macOS with:

- **Bundle ID**: `org.baytides.navigator.macos`
- **SKU**: `baynavigator-macos`

And for visionOS with:

- **Bundle ID**: `org.baytides.navigator.visionos`
- **SKU**: `baynavigator-visionos`

## 5. App Store Connect API Key (for CI/CD)

Go to [Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)

1. Click **"+"** to generate a new key
2. Name: `GitHub Actions`
3. Access: **App Manager** (or Admin if needed)
4. Download the `.p8` key file (you can only download it once!)
5. Note the **Key ID** and **Issuer ID** shown on the page

Add to GitHub secrets:

```bash
# Base64 encode the key
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
```

- `APP_STORE_CONNECT_API_KEY_BASE64`: The base64-encoded `.p8` key
- `APP_STORE_CONNECT_API_KEY_ID`: The Key ID (e.g., `XXXXXXXXXX`)
- `APP_STORE_CONNECT_API_ISSUER_ID`: The Issuer ID (UUID format)

## 6. GitHub Repository Secrets Summary

Add these secrets to your repository at **Settings → Secrets and variables → Actions**:

| Secret Name                            | Description                                  |
| -------------------------------------- | -------------------------------------------- |
| `IOS_CERTIFICATE_BASE64`               | Base64-encoded .p12 distribution certificate |
| `IOS_CERTIFICATE_PASSWORD`             | Password for the .p12 certificate            |
| `IOS_PROVISIONING_PROFILE_BASE64`      | Base64-encoded iOS provisioning profile      |
| `MACOS_PROVISIONING_PROFILE_BASE64`    | Base64-encoded macOS provisioning profile    |
| `VISIONOS_PROVISIONING_PROFILE_BASE64` | Base64-encoded visionOS provisioning profile |
| `APP_STORE_CONNECT_API_KEY_BASE64`     | Base64-encoded .p8 API key                   |
| `APP_STORE_CONNECT_API_KEY_ID`         | API Key ID                                   |
| `APP_STORE_CONNECT_API_ISSUER_ID`      | API Issuer ID                                |

## 7. Test the Setup

### Local Build Test

```bash
cd apps/apple

# Build for iOS Simulator (no signing required)
xcodebuild -scheme "Bay Navigator (iOS)" \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  build

# Build for device (requires signing)
xcodebuild -scheme "Bay Navigator (iOS)" \
  -destination "generic/platform=iOS" \
  -configuration Release \
  archive
```

### Trigger GitHub Actions

1. Create and push a version tag:

   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

2. Or manually trigger the workflow from GitHub Actions tab

## 8. App Store Listing Preparation

Before submitting to the App Store, prepare:

### Required Assets

- **App Icon**: 1024x1024 PNG (no alpha/transparency)
- **Screenshots**:
  - iPhone 6.7" (1290 x 2796)
  - iPhone 6.5" (1284 x 2778)
  - iPad Pro 12.9" (2048 x 2732)
  - Mac (1280 x 800 minimum)
  - Apple Vision Pro (if applicable)

### App Information

- **App Name**: Bay Navigator
- **Subtitle**: Discover Bay Area Benefits
- **Description**: (see store_listings/)
- **Keywords**: benefits, discounts, Bay Area, assistance, programs
- **Support URL**: https://baynavigator.org/support
- **Privacy Policy URL**: https://baynavigator.org/privacy
- **Category**: Lifestyle (primary), Utilities (secondary)
- **Age Rating**: 4+ (no objectionable content)

### Review Notes

Include notes for App Review:

```
Bay Navigator helps Bay Area residents discover discount and assistance
programs they may qualify for. The app aggregates publicly available
information from government and nonprofit sources.

No login required. Location is used optionally to show nearby programs.
All data processing happens on-device for privacy.
```

## Troubleshooting

### "No signing certificate" error

- Ensure the distribution certificate is installed in Keychain
- Check that Xcode can access the keychain

### "Provisioning profile doesn't include signing certificate"

- Regenerate the provisioning profile after creating a new certificate
- Download and reinstall the updated profile

### "Bundle ID is not available"

- Someone already registered that bundle ID
- Use a different bundle ID or contact Apple Support

### TestFlight build not appearing

- Wait 15-30 minutes for processing
- Check email for any compliance issues
- Verify the build uploaded successfully in App Store Connect
