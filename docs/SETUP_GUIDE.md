# HealthBrowser Setup Guide

Complete step-by-step guide to set up and run the HealthBrowser project.

## Prerequisites

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **iOS Device**: iPhone with iOS 16.0+ (physical device required for HealthKit)
- **Apple Developer Account**: Required for HealthKit entitlements and CloudKit
- **iCloud Account**: Required for data sync between devices

## Step 1: Clone the Repository

```bash
git clone https://github.com/Flipajs/HealthBrowserMac.git
cd HealthBrowserMac
```

## Step 2: Create Xcode Workspace

Since Xcode projects can't be easily committed to Git (they contain user-specific paths), you'll need to create the workspace manually:

### Create iOS App

1. Open Xcode
2. **File → New → Project**
3. Select **iOS → App**
4. Configure:
   - **Product Name**: HealthBrowseriOS
   - **Team**: Select your Apple Developer team
   - **Organization Identifier**: com.filipnaiser (or your identifier)
   - **Bundle Identifier**: com.filipnaiser.HealthBrowseriOS
   - **Interface**: SwiftUI
   - **Language**: Swift
5. **Save** in the `iOS/` directory of the cloned repo

### Create macOS App

1. **File → New → Project**
2. Select **macOS → App**
3. Configure:
   - **Product Name**: HealthBrowserMac
   - **Team**: Select your Apple Developer team
   - **Organization Identifier**: com.filipnaiser
   - **Bundle Identifier**: com.filipnaiser.HealthBrowserMac
   - **Interface**: SwiftUI
   - **Language**: Swift
4. **Save** in the `macOS/` directory

### Create Workspace

1. **File → New → Workspace**
2. Name it **HealthBrowser.xcworkspace**
3. Save in the **root** directory of the repo
4. **File → Add Files to Workspace**
5. Add both `HealthBrowseriOS.xcodeproj` and `HealthBrowserMac.xcodeproj`

## Step 3: Add Source Files to Targets

### Add iOS Files

1. In Xcode, select **HealthBrowseriOS** project
2. Right-click on the **HealthBrowseriOS** group
3. **Add Files to "HealthBrowseriOS"**
4. Navigate to `iOS/HealthBrowseriOS/` in the repo
5. Select all `.swift` files
6. ✅ Ensure **HealthBrowseriOS target** is checked
7. Click **Add**

### Add macOS Files

1. Select **HealthBrowserMac** project
2. Right-click on the **HealthBrowserMac** group
3. **Add Files to "HealthBrowserMac"**
4. Navigate to `macOS/HealthBrowserMac/` in the repo
5. Select all files in `Views/` and `Utilities/` folders
6. ✅ Ensure **HealthBrowserMac target** is checked
7. Click **Add**

### Add Shared Files (CRITICAL)

1. Select either project
2. Right-click and **Add Files to Workspace**
3. Navigate to `Shared/Models/` in the repo
4. Select:
   - `HealthBrowser.xcdatamodeld`
   - All `*.swift` files (PersistenceController, CoreData classes)
5. ✅ Check **BOTH** targets: HealthBrowseriOS AND HealthBrowserMac
6. Click **Add**

> **Why both targets?** CoreData models must be identical on iOS and macOS for CloudKit sync to work.

## Step 4: Configure Apple Developer Account

### Create CloudKit Container

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. **Certificates, Identifiers & Profiles**
3. **Identifiers → CloudKit Containers**
4. Click **+** to create new container
5. **Container ID**: `iCloud.com.filipnaiser.HealthBrowser`
6. **Description**: HealthBrowser Data Sync
7. Click **Continue** and **Register**

### Create App Group

1. Still in **Identifiers** section
2. **App Groups**
3. Click **+** to create new group
4. **Identifier**: `group.com.filipnaiser.HealthBrowser`
5. **Description**: HealthBrowser Shared Data
6. Click **Continue** and **Register**

## Step 5: Configure iOS Target Capabilities

1. Select **HealthBrowseriOS** target in Xcode
2. Go to **Signing & Capabilities** tab

### Add HealthKit

1. Click **+ Capability**
2. Search for **HealthKit**
3. Click to add
4. ✅ Clinical Health Records: **OFF** (not needed)

### Add iCloud

1. Click **+ Capability**
2. Search for **iCloud**
3. Click to add
4. ✅ Enable **CloudKit**
5. Under **Containers**, click **+**
6. Select `iCloud.com.filipnaiser.HealthBrowser`

### Add App Groups

1. Click **+ Capability**
2. Search for **App Groups**
3. Click to add
4. Click **+** to add group
5. Enter `group.com.filipnaiser.HealthBrowser`
6. ✅ Ensure it's checked

### Add Background Modes

1. Click **+ Capability**
2. Search for **Background Modes**
3. Click to add
4. ✅ Enable **Background fetch**
5. ✅ Enable **Background processing**

## Step 6: Configure macOS Target Capabilities

1. Select **HealthBrowserMac** target
2. Go to **Signing & Capabilities** tab

### Add iCloud

1. Click **+ Capability**
2. Add **iCloud**
3. ✅ Enable **CloudKit**
4. Select **SAME** container: `iCloud.com.filipnaiser.HealthBrowser`

### Add App Groups

1. Click **+ Capability**
2. Add **App Groups**
3. Select **SAME** group: `group.com.filipnaiser.HealthBrowser`

## Step 7: Add Privacy Descriptions (iOS Only)

1. Select **HealthBrowseriOS** target
2. Go to **Info** tab
3. Right-click in the list → **Add Row**
4. Add these keys:

```xml
Privacy - Health Share Usage Description
Value: "HealthBrowser needs access to read your health data to display it on your Mac."

Privacy - Health Update Usage Description  
Value: "HealthBrowser does not write data to Health app."
```

Or edit `Info.plist` directly:

```xml
<key>NSHealthShareUsageDescription</key>
<string>HealthBrowser needs access to read your health data to display it on your Mac.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>HealthBrowser does not write data to Health app.</string>
```

## Step 8: Update PersistenceController

Open `Shared/Models/PersistenceController.swift` and verify the CloudKit container identifier matches:

```swift
let cloudKitOptions = NSPersistentCloudKitContainerOptions(
    containerIdentifier: "iCloud.com.filipnaiser.HealthBrowser"
)
```

If you used a different identifier, update it here.

## Step 9: Build and Run

### Run iOS App

1. Connect your iPhone via USB
2. Select **HealthBrowseriOS** scheme
3. Select your iPhone as the destination
4. Click **Run** (⌘R)
5. **Trust Developer** on iPhone if prompted
6. Grant HealthKit permissions when app launches
7. Tap **Authorize HealthKit**
8. Allow all requested permissions
9. Tap **Sync Now**

### Run macOS App

1. Select **HealthBrowserMac** scheme
2. Select **My Mac** as destination
3. Click **Run** (⌘R)
4. Wait 10-30 seconds for CloudKit sync
5. Data should appear in the browser!

## Step 10: Verify Sync

### Check iOS App

- Sync status should show "Synced"
- Metric counts should be displayed (Steps, Heart Rate, etc.)
- Last sync time should be recent

### Check macOS App

- Select a category in the sidebar (e.g., Steps)
- List should populate with synced data
- Click on a metric to see details
- Charts should render (if data available)

### Troubleshooting Sync Issues

**Data not appearing on Mac?**

1. Verify both apps use the **same** iCloud account (Settings → Apple ID)
2. Check internet connection on both devices
3. In iOS app, tap **Sync Now** again
4. Wait 30-60 seconds, then check macOS app
5. Restart macOS app to force CloudKit refresh

**CloudKit Quota Error?**

- Free tier: 1GB database, 10GB assets, 40GB transfer/month
- For development, this is plenty
- If exceeded, wait for monthly reset or upgrade Apple Developer plan

**HealthKit Authorization Failed?**

- Go to iPhone Settings → Privacy & Security → Health → HealthBrowser
- Ensure all permissions are granted
- Delete and reinstall iOS app if needed

## Next Steps

### Test with Real Data

1. Go for a walk/run with Apple Watch
2. Complete a workout
3. Let Apple Watch record heart rate and steps
4. Open iOS app and sync
5. Check macOS app for new data

### Explore Features

- Browse different metric categories
- Change date ranges (Today, Week, Month, Year)
- Export data to CSV/JSON
- View charts and statistics

### Development

- Add breakpoints to debug sync issues
- Check Xcode console for CloudKit sync logs
- Monitor CoreData fetch requests
- Profile performance with Instruments

## Common Issues

### "HealthKit not available"

- You're running on simulator → Use physical iPhone
- HealthKit capability not added → Revisit Step 5

### "CloudKit sync not working"

- Different iCloud accounts on iOS/macOS → Use same account
- Container identifier mismatch → Verify Step 4 and Step 8
- Network issues → Check internet connection

### "App won't build"

- Missing files → Verify Step 3 (all files added to targets)
- Signing issues → Check Team selection in target settings
- Swift version mismatch → Use Xcode 15+ with Swift 5.9

### "CoreData crash"

- Model not shared between targets → Ensure Shared/Models added to BOTH targets
- Container identifier wrong → Check PersistenceController.swift

## Additional Resources

- [Apple HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [Swift Charts Guide](https://developer.apple.com/documentation/charts)
- [Project GitHub Issues](https://github.com/Flipajs/HealthBrowserMac/issues)

---

**Setup complete!** 🎉 You should now have a working HealthBrowser installation syncing data from iPhone to Mac.
