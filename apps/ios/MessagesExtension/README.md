# Bay Navigator iMessage Extension

This iMessage extension allows users to share saved programs directly within iMessage conversations.

## Setup Instructions

### 1. Add the Extension Target in Xcode

1. Open `Runner.xcworkspace` in Xcode
2. Go to **File > New > Target**
3. Select **iMessage Extension** under iOS
4. Name it `MessagesExtension`
5. Set the Bundle Identifier to `org.baytides.baynavigator.MessagesExtension`
6. Click **Finish**

### 2. Configure App Groups

Both the main app and the extension need to share the same App Group:

1. Select the **Runner** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** and add **App Groups**
4. Add `group.org.baytides.baynavigator`

5. Select the **MessagesExtension** target
6. Go to **Signing & Capabilities**
7. Click **+ Capability** and add **App Groups**
8. Add the same group: `group.org.baytides.baynavigator`

### 3. Add Source Files

In Xcode, add the following files to the MessagesExtension target:
- `MessagesViewController.swift`
- `MessageContentView.swift`
- `SharedDataManager.swift`
- `Assets.xcassets`

### 4. Configure Build Settings

1. Select the **MessagesExtension** target
2. In **Build Settings**, set:
   - **iOS Deployment Target**: 15.0 (or match main app)
   - **Swift Language Version**: 5.0

### 5. Update Info.plist

Ensure the `Info.plist` is properly configured with:
- `NSExtension` dictionary with `NSExtensionPointIdentifier` set to `com.apple.message-payload-provider`
- `NSExtensionPrincipalClass` set to `$(PRODUCT_MODULE_NAME).MessagesViewController`

### 6. Add App Icon

Add a 1024x768 PNG image named `messages-app-icon-1024x768.png` to the `Assets.xcassets/iMessage App Icon.stickersiconset` folder.

## How It Works

1. **Flutter App** saves favorite programs to SharedPreferences
2. When favorites change, `IMessageService` syncs them via a method channel
3. **AppDelegate** receives the data and writes to the shared App Group container
4. **MessagesExtension** reads from the App Group to display saved programs
5. Users can browse and send program cards directly in iMessage

## Testing

1. Build and run the main app on a device/simulator
2. Save some programs as favorites
3. Open Messages app
4. Tap the App Store icon in the message composer
5. Find "Bay Navigator" in the app drawer
6. Browse and send saved programs!

## Troubleshooting

- **Extension not showing**: Ensure both targets have the same App Group configured
- **No programs appearing**: Check that favorites are being saved in the main app
- **Build errors**: Verify Swift files are added to the correct target membership
