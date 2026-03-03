# HealthBrowser for macOS

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013.0%2B-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI-4.0-green.svg" alt="SwiftUI">
  <img src="https://img.shields.io/badge/license-MIT-lightgrey.svg" alt="License">
</p>

A native macOS application for browsing and visualizing Apple Health data synced from your iPhone. Built with SwiftUI, HealthKit, and CloudKit.

## 🎯 Project Status

**Current Phase:** POC Development (Week 1-3)

- [x] Project initialization
- [ ] iOS companion app with HealthKit integration
- [ ] CloudKit sync infrastructure
- [ ] macOS browser UI
- [ ] Core visualizations with Swift Charts
- [ ] CSV/JSON export functionality

## 🚀 Features

### MVP (Phase 1)
- ✅ **iOS Companion App**: Reads HealthKit data from your iPhone
- ✅ **CloudKit Sync**: Automatic sync to your Mac via iCloud
- ✅ **Core Metrics**: Steps, heart rate, workouts, calories, sleep
- ✅ **Time-Series Visualizations**: Line charts, bar charts, summary cards
- ✅ **Date Range Filtering**: Today, week, month, year, all time
- ✅ **Data Export**: CSV and JSON formats

### Planned (Phase 2+)
- 🔄 Rowing workout specialization
- 🔄 Advanced visualizations (heatmaps, correlation plots)
- 🔄 Local AI analysis with Ollama
- 🔄 Goal tracking and trend prediction
- 🔄 Third-party integrations (Strava, Training Peaks)

## 🏗️ Architecture

```
┌─────────────────┐         ┌──────────────────┐
│   iOS App       │         │   macOS App      │
│  (Companion)    │◄───────►│   (Browser)      │
│                 │  Sync   │                  │
│ ┌─────────────┐ │         │ ┌──────────────┐ │
│ │ HealthKit   │ │         │ │ CoreData +   │ │
│ │ Manager     │ │         │ │ CloudKit     │ │
│ └─────────────┘ │         │ └──────────────┘ │
│ ┌─────────────┐ │         │ ┌──────────────┐ │
│ │ CloudKit    │ │         │ │ SwiftUI      │ │
│ │ Sync        │ │         │ │ Charts       │ │
│ └─────────────┘ │         │ └──────────────┘ │
└─────────────────┘         └──────────────────┘
        │                            │
        └────────── iCloud ──────────┘
              (CKContainer)
```

## 🛠️ Tech Stack

- **iOS App**: SwiftUI, HealthKit framework
- **macOS App**: SwiftUI, Swift Charts
- **Data Sync**: CloudKit (NSPersistentCloudKitContainer)
- **Local Database**: CoreData with CloudKit sync
- **Visualizations**: Swift Charts (macOS 13+)
- **Export**: CSV/JSON serialization

## 📋 Requirements

- **macOS**: 13.0 (Ventura) or later
- **iOS**: 16.0 or later
- **Xcode**: 15.0 or later
- **iCloud Account**: Required for CloudKit sync
- **Apple Developer Account**: Required for HealthKit entitlements

## 🚦 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/Flipajs/HealthBrowserMac.git
cd HealthBrowserMac
```

### 2. Open Xcode Workspace

```bash
open HealthBrowser.xcworkspace
```

### 3. Configure CloudKit

1. Select the iOS target in Xcode
2. Go to **Signing & Capabilities**
3. Add **iCloud** capability
4. Enable **CloudKit**
5. Create or select a CloudKit container (e.g., `iCloud.com.yourteam.HealthBrowser`)
6. Add **App Groups** capability
7. Create app group: `group.com.yourteam.HealthBrowser`
8. Repeat for macOS target with same container and app group

### 4. Configure HealthKit (iOS Only)

1. Select iOS target
2. Add **HealthKit** capability
3. Update `Info.plist` with privacy descriptions:
   - `NSHealthShareUsageDescription`: "HealthBrowser needs access to read your health data to display it on your Mac."
   - `NSHealthUpdateUsageDescription`: "HealthBrowser does not write data to Health app."

### 5. Build and Run

1. **iOS App**: Select your iPhone as target, build and run
2. Grant HealthKit permissions when prompted
3. **macOS App**: Select Mac target, build and run
4. Wait for CloudKit sync (may take 10-30 seconds initially)
5. Browse your health data!

## 📖 Documentation

- [POC Development Plan](docs/POC_PLAN.md) - Detailed 3-week implementation roadmap
- [Architecture Guide](docs/ARCHITECTURE.md) - System design and data flow
- [API Documentation](docs/API.md) - HealthKit integration details
- [Contributing Guidelines](CONTRIBUTING.md) - How to contribute

## 🎯 Roadmap

### Week 1-3: POC/MVP
- iOS companion app with HealthKit
- CloudKit sync infrastructure
- macOS browser with basic charts
- CSV/JSON export

### Week 4-8: Enhanced Features
- Advanced visualizations
- Rowing workout specialization
- Smart filtering and search
- Weekly/monthly reports

### Week 9+: Premium Features
- Local AI analysis (Ollama)
- Predictive models
- Third-party integrations
- Pro visualizations

## 💰 Monetization

- **Free Tier**: Basic browsing and visualization (5 core metrics)
- **One-Time Purchase**: $10-20 for full metric access and export
- **Premium Subscription**: $5/month for AI analysis, advanced sync, integrations

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Apple HealthKit and CloudKit frameworks
- Swift Charts for native visualizations
- Inspiration from Health.md and Health Auto Export
- Rowing and Apple Watch communities for feedback

## 📧 Contact

- **Developer**: Filip Naiser
- **Email**: filip.naiser@gmail.com
- **GitHub**: [@Flipajs](https://github.com/Flipajs)

---

**Note**: This app is not affiliated with Apple Inc. Apple Health and HealthKit are trademarks of Apple Inc.