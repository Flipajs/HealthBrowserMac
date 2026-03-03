# macOS Health Data Browser - POC Development Plan

## Executive Summary

Apple does not provide native HealthKit support for macOS applications, despite the framework being present in the SDK. This creates a significant market opportunity for a third-party health data browser that syncs iPhone Health data to Mac for browsing, analysis, and visualization. Based on market research, existing solutions (Health.md, Health Auto Export) demonstrate demand, but none dominate the space with polished UX and advanced features.

**Target POC Timeline:** 2-3 weeks for MVP with core browsing capabilities.

**Revenue Potential:** 10,000 users at $10-20 one-time purchase = $100-200k annual revenue, scalable to subscription model ($2-5/month) for premium features.

---

## Technical Feasibility Assessment

### HealthKit macOS Reality

- HealthKit framework exists in macOS SDK (macOS 13.0+) but `HKHealthStore.isHealthDataAvailable()` returns `false` on Mac
- No direct HealthKit access on macOS — data syncing must happen via alternative methods
- iPhone/iPad HealthKit APIs fully functional for iOS apps

### Data Access Strategies

**Strategy 1: iOS Companion App (Recommended for POC)**
- Build iOS app that reads HealthKit data
- Sync to Mac via iCloud CloudKit or local network (Bonjour/Multipeer Connectivity)
- macOS app consumes synced data from shared database
- Privacy: All data processing on-device or via user's iCloud

**Strategy 2: XML Export Parser**
- User manually exports Health data as XML from iPhone (Health app → Profile → Export All Health Data)
- macOS app parses massive XML file (often 100MB+, can crash Excel)
- One-time import, no live sync
- Useful as fallback option

**Strategy 3: Third-Party SDK (Terra API)**
- Use services like Terra.co for standardized health data integration
- Adds external dependency and privacy concerns
- Not recommended for indie SaaS focused on privacy

---

## Market Analysis

### Existing Solutions

| App | Features | Price | Gap |
|-----|----------|-------|-----|
| Health.md | Markdown/JSON/CSV export, local sync | $10 one-time | Limited visualization, no ML |
| Health Auto Export | Auto-sync, 150+ metrics, widgets | Freemium/Sub | iOS-focused, basic Mac support |
| Apple Health Export | XML dump only | Free | Unusable without conversion |

### Market Opportunity

- **Underserved niche**: No dominant macOS-native Health browser with polished UX
- **Target users**: Fitness enthusiasts (rowing, cycling, running), developers/data analysts, Apple Watch power users
- **Pain points**:
  - iPhone screen too small for detailed trend analysis
  - No way to browse years of historical data efficiently on Mac
  - Existing tools lack ML-powered insights (anomaly detection, trend prediction)
- **Differentiators**: Local AI analysis (Ollama), privacy-first architecture, rowing/Apple Watch specialization

---

## Feature Roadmap

### Phase 1: POC/MVP (Week 1-3)

**Must-Have Features:**

1. **Data Sync Foundation**
   - iOS companion app with HealthKit authorization (steps, heart rate, workouts)
   - CloudKit sync to macOS app via shared container
   - Basic data model: Store last 90 days of metrics

2. **macOS Browser Core**
   - SwiftUI app with three-pane layout (sidebar, list, detail)
   - Date range selector (today, week, month, year, all time)
   - Metric categories: Activity (steps, calories), Vitals (HR, HRV), Workouts

3. **Basic Visualization**
   - Line charts for time-series data (steps per day, resting HR trend)
   - Summary cards with daily/weekly/monthly aggregates
   - Use Swift Charts framework (native to macOS 13+)

4. **Export Functionality**
   - Export selected data to CSV/JSON
   - Backup entire database to local file

**Success Criteria:**
- Sync 5+ core metrics from iPhone to Mac reliably
- Browse and visualize 90 days of historical data
- Export data in usable format
- Zero crashes, clean UI

### Phase 2: Enhanced Features (Week 4-8)

1. **Advanced Visualizations** — Heatmaps, correlation plots, customizable dashboard
2. **Rowing Specialization** — Stroke rate, split times, Concept2 integration
3. **Smart Filtering and Search** — Full-text search, saved filters, custom views
4. **Data Insights** — PDF reports, trend detection, goal tracking

### Phase 3: Premium/AI Features (Week 9+)

**Premium Subscription Features ($2-5/month):**

1. **Local AI Analysis** — Anomaly detection, predictive models, natural language queries via Ollama
2. **Advanced Syncing** — Real-time local network sync, multi-device, historical backfill
3. **Third-Party Integrations** — Strava, Training Peaks, Garmin Connect
4. **Pro Visualizations** — 3D workout maps, video overlay, custom notebooks

---

## Implementation Plan

### Architecture Overview

```
┌─────────────────┐         ┌──────────────────┐
│   iOS App       │         │   macOS App      │
│  (Companion)    │◄───────►│   (Browser)      │
│                 │  Sync   │                  │
│ ┌─────────────┐ │         │ ┌──────────────┐ │
│ │ HealthKit   │ │         │ │ Data Model   │ │
│ │ Manager     │ │         │ │ (CoreData)   │ │
│ └─────────────┘ │         │ └──────────────┘ │
│ ┌─────────────┐ │         │ ┌──────────────┐ │
│ │ CloudKit    │ │         │ │ SwiftUI      │ │
│ │ Sync Engine │ │         │ │ Browser UI   │ │
│ └─────────────┘ │         │ └──────────────┘ │
└─────────────────┘         └──────────────────┘
        │                            │
        └────────── iCloud ──────────┘
              (CKContainer)
```

### Tech Stack

| Component | Technology |
|-----------|------------|
| iOS App | SwiftUI, HealthKit framework |
| macOS App | SwiftUI, Swift Charts |
| Data Sync | CloudKit (shared container) |
| Local DB | CoreData with CloudKit sync |
| Charts | Swift Charts (macOS 13+) |
| Export | CSV/JSON serialization |
| AI (Phase 3) | Ollama (local LLM) |

---

## Step-by-Step Implementation Guide

### Week 1: Foundation (Days 1-7)

---

#### Day 1: Project Setup

**Step 1.1: Create Xcode Workspace**

1. Open Xcode 15+, select "Create New Project"
2. Choose "iOS App" template, name it `HealthSyncCompanion`
   - Interface: SwiftUI, Language: Swift
   - Organization Identifier: `com.yourname.healthsync`
3. Add macOS target: File → New → Target → macOS → App → `HealthBrowser`
4. Create Workspace: File → Save As Workspace → `HealthSync.xcworkspace`

**Step 1.2: Configure Capabilities**

For iOS target (`HealthSyncCompanion`):
1. Select target → Signing & Capabilities → `+ Capability`:
   - **HealthKit** — enables HealthKit framework
   - **Background Modes** — enable "Background fetch"
   - **iCloud** — enable "CloudKit" with default container
   - **App Groups** — create `group.com.yourname.healthsync.shared`
2. Add to `Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>This app needs access to your health data to sync with your Mac for analysis and visualization.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>This app may write workout data to Health.</string>
```

For macOS target (`HealthBrowser`):
- **iCloud** — use SAME container as iOS
- **App Groups** — use SAME group `group.com.yourname.healthsync.shared`

**Step 1.3: CloudKit Container Setup**

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/)
2. Select your default container (auto-created by Xcode)
3. Schema is auto-created by `NSPersistentCloudKitContainer` — no manual setup needed
4. Verify container ID in both targets: `iCloud.com.yourname.healthsync`

**Step 1.4: Shared Code Architecture**

Create a `Shared/` group added to both targets:
- `HealthMetric.swift` — data model
- `HealthDataModel.xcdatamodeld` — CoreData schema
- `MetricType.swift` — enum for metric types

```swift
// Shared/MetricType.swift
enum MetricType: String, Codable, CaseIterable {
    case steps = "Steps"
    case heartRate = "Heart Rate"
    case activeCalories = "Active Calories"
    case restingHeartRate = "Resting Heart Rate"
    case workout = "Workout"
    case sleep = "Sleep"

    var unit: String {
        switch self {
        case .steps: return "steps"
        case .heartRate, .restingHeartRate: return "bpm"
        case .activeCalories: return "kcal"
        case .workout: return "minutes"
        case .sleep: return "hours"
        }
    }
}
```

**Step 1.5: Git Repository Initialization**

```bash
cd /path/to/HealthSync
git init
git add .
git commit -m "Initial project setup: iOS companion + macOS browser with CloudKit"

cat > .gitignore << 'EOF'
*.xcuserstate
*.xcworkspace/xcuserdata/
DerivedData/
build/
.swiftpm/
Packages/
EOF

git add .gitignore
git commit -m "Add .gitignore for Xcode"
```

---

#### Days 2-3: iOS HealthKit Integration

**Step 2.1: Create HealthKitManager**

```swift
// iOS/HealthKitManager.swift
import Foundation
import HealthKit

@MainActor
class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    let typesToRead: Set<HKObjectType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.heartRate),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.appleExerciseTime),
        HKCategoryType(.sleepAnalysis),
        HKWorkoutType.workoutType()
    ]

    func requestAuthorization() async throws {
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }
}
```

**Step 2.2: Data Fetching Methods**

```swift
// Fetch daily step statistics (aggregated per day)
func fetchDailySteps(for days: Int = 30) async throws -> [HealthMetric] {
    let stepType = HKQuantityType(.stepCount)
    let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    var interval = DateComponents()
    interval.day = 1

    return try await withCheckedThrowingContinuation { continuation in
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: interval
        )
        query.initialResultsHandler = { _, results, error in
            if let error = error { continuation.resume(throwing: error); return }
            var metrics: [HealthMetric] = []
            results?.enumerateStatistics(from: startDate, to: Date()) { stats, _ in
                if let sum = stats.sumQuantity() {
                    metrics.append(HealthMetric(
                        type: .steps,
                        value: sum.doubleValue(for: .count()),
                        date: stats.startDate,
                        source: "Daily Aggregate"
                    ))
                }
            }
            continuation.resume(returning: metrics)
        }
        healthStore.execute(query)
    }
}

// Fetch heart rate samples
func fetchHeartRate(from startDate: Date, to endDate: Date) async throws -> [HealthMetric] {
    let hrType = HKQuantityType(.heartRate)
    let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

    return try await withCheckedThrowingContinuation { continuation in
        let query = HKSampleQuery(
            sampleType: hrType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            if let error = error { continuation.resume(throwing: error); return }
            let metrics = (samples as? [HKQuantitySample])?.map { sample in
                HealthMetric(
                    type: .heartRate,
                    value: sample.quantity.doubleValue(for: HKUnit(from: "count/min")),
                    date: sample.startDate,
                    source: sample.sourceRevision.source.name
                )
            } ?? []
            continuation.resume(returning: metrics)
        }
        healthStore.execute(query)
    }
}
```

**Step 2.3: HealthMetric Shared Struct**

```swift
// Shared/HealthMetric.swift
import Foundation

struct HealthMetric: Identifiable, Codable {
    let id: UUID
    let type: MetricType
    let value: Double
    let date: Date
    let source: String

    init(id: UUID = UUID(), type: MetricType, value: Double, date: Date, source: String) {
        self.id = id; self.type = type; self.value = value
        self.date = date; self.source = source
    }

    var displayValue: String { String(format: "%.1f", value) }
}
```

**Step 2.4: iOS Test View**

```swift
struct ContentView: View {
    @StateObject private var healthManager = HealthKitManager()
    @State private var authorizationStatus = "Not requested"
    @State private var stepData: [HealthMetric] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Status: \(authorizationStatus)").font(.headline)

                Button("Request Authorization") {
                    Task {
                        do {
                            try await healthManager.requestAuthorization()
                            authorizationStatus = "Authorized"
                        } catch { authorizationStatus = "Error: \(error.localizedDescription)" }
                    }
                }.buttonStyle(.borderedProminent)

                Button("Fetch Last 7 Days Steps") {
                    Task {
                        stepData = (try? await healthManager.fetchDailySteps(for: 7)) ?? []
                    }
                }.buttonStyle(.bordered).disabled(authorizationStatus != "Authorized")

                List(stepData) { metric in
                    HStack {
                        Text(metric.date.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        Text("\(metric.displayValue) steps").foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .navigationTitle("Health Sync Companion")
        }
    }
}
```

> **Note:** Simulator does not have real HealthKit data. Test on a physical iPhone with Apple Watch data.

---

#### Days 4-5: CoreData + CloudKit Sync

**Step 3.1: CoreData Model**

In Xcode → File → New → Core Data → Data Model → `HealthDataModel` (add to both targets).

Add entity `HealthMetricEntity` with attributes:
- `id`: UUID
- `type`: String
- `value`: Double
- `date`: Date
- `source`: String
- `createdAt`: Date

**Step 3.2: PersistenceController with CloudKit**

```swift
// Shared/PersistenceController.swift
import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "HealthDataModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("No store description found")
            }
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            let ckOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.yourname.healthsync"
            )
            description.cloudKitContainerOptions = ckOptions
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? { fatalError("CoreData error: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Post notification on CloudKit import
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container, queue: .main
        ) { notification in
            if let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event {
                if event.type == .import {
                    NotificationCenter.default.post(name: .cloudKitDidSync, object: nil)
                }
                if let error = event.error {
                    NotificationCenter.default.post(name: .cloudKitSyncError, object: error)
                }
            }
        }
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        try? context.save()
    }
}

extension Notification.Name {
    static let cloudKitDidSync = Notification.Name("cloudKitDidSync")
    static let cloudKitSyncError = Notification.Name("cloudKitSyncError")
}
```

**Step 3.3: DataManager CRUD**

```swift
// Shared/DataManager.swift
import CoreData

@MainActor
class DataManager: ObservableObject {
    let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    var context: NSManagedObjectContext { persistenceController.container.viewContext }

    func saveMetrics(_ metrics: [HealthMetric]) throws {
        for metric in metrics {
            let entity = HealthMetricEntity(context: context)
            entity.id = metric.id
            entity.type = metric.type.rawValue
            entity.value = metric.value
            entity.date = metric.date
            entity.source = metric.source
            entity.createdAt = Date()
        }
        try context.save()
    }

    func fetchMetrics(from startDate: Date, to endDate: Date, type: MetricType? = nil) -> [HealthMetric] {
        let request = HealthMetricEntity.fetchRequest()
        var predicates: [NSPredicate] = [
            NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        ]
        if let type = type {
            predicates.append(NSPredicate(format: "type == %@", type.rawValue))
        }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HealthMetricEntity.date, ascending: true)]

        return (try? context.fetch(request))?.compactMap { entity in
            guard let id = entity.id, let typeStr = entity.type,
                  let type = MetricType(rawValue: typeStr),
                  let date = entity.date, let source = entity.source else { return nil }
            return HealthMetric(id: id, type: type, value: entity.value, date: date, source: source)
        } ?? []
    }

    func pruneOldData(olderThan days: Int = 90) throws {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let request = HealthMetricEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date < %@", cutoff as NSDate)
        let entities = try context.fetch(request)
        entities.forEach { context.delete($0) }
        try context.save()
    }
}
```

**Step 3.4: Sync from iOS**

```swift
// Add to HealthKitManager
func syncRecentData() async throws {
    let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    let steps = try await fetchDailySteps(for: 7)
    try dataManager.saveMetrics(steps)

    let heartRate = try await fetchHeartRate(from: startDate, to: Date())
    try dataManager.saveMetrics(Array(heartRate.prefix(100)))
    print("Synced \(steps.count) step entries and \(min(heartRate.count, 100)) HR samples")
}
```

> **Verify:** Check [CloudKit Dashboard](https://icloud.developer.apple.com/) → Data → Production for `CD_HealthMetricEntity` records after syncing.

---

#### Days 6-7: macOS Browser UI

**Step 4.1: ContentView with NavigationSplitView**

```swift
// macOS/ContentView.swift
import SwiftUI

enum ViewType { case dashboard, browser }

enum DateRange: String, CaseIterable {
    case today = "Today", lastWeek = "Last 7 Days"
    case lastMonth = "Last 30 Days", lastYear = "Last Year", allTime = "All Time"

    var dateRange: (start: Date, end: Date) {
        let now = Date(), cal = Calendar.current
        switch self {
        case .today:    return (cal.startOfDay(for: now), now)
        case .lastWeek: return (cal.date(byAdding: .day, value: -7, to: now)!, now)
        case .lastMonth:return (cal.date(byAdding: .day, value: -30, to: now)!, now)
        case .lastYear: return (cal.date(byAdding: .year, value: -1, to: now)!, now)
        case .allTime:  return (cal.date(from: DateComponents(year: 2020, month: 1, day: 1))!, now)
        }
    }
}

struct ContentView: View {
    @StateObject private var dataManager = DataManager()
    @StateObject private var syncStatus = SyncStatusManager()
    @State private var selectedView: ViewType = .dashboard
    @State private var selectedMetricType: MetricType? = .steps
    @State private var selectedDateRange: DateRange = .lastWeek
    @State private var metrics: [HealthMetric] = []

    var body: some View {
        NavigationSplitView {
            sidebar
        } content: {
            if selectedView == .dashboard { DashboardView() }
            else { metricsList }
        } detail: {
            detailView
        }
        .toolbar {
            ToolbarItem(placement: .status) { SyncStatusView(syncManager: syncStatus) }
            ToolbarItem(placement: .automatic) { dateRangePicker }
            ToolbarItem(placement: .automatic) { refreshButton }
            ToolbarItem(placement: .automatic) { exportMenu }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cloudKitDidSync)) { _ in
            syncStatus.finishSync(); loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cloudKitSyncError)) { n in
            syncStatus.finishSync(error: n.object as? Error)
        }
        .onAppear { loadData() }
    }

    // MARK: Sidebar
    private var sidebar: some View {
        List(selection: $selectedMetricType) {
            Section("Views") {
                Label("Dashboard", systemImage: "square.grid.2x2").tag(nil as MetricType?)
                    .onTapGesture { selectedView = .dashboard }
                Label("Browser", systemImage: "list.bullet").tag(nil as MetricType?)
                    .onTapGesture { selectedView = .browser }
            }
            Section("Activity") {
                Label("Steps", systemImage: "figure.walk").tag(MetricType.steps)
                Label("Calories", systemImage: "flame.fill").tag(MetricType.activeCalories)
            }
            Section("Vitals") {
                Label("Heart Rate", systemImage: "heart.fill").tag(MetricType.heartRate)
                Label("Resting HR", systemImage: "heart").tag(MetricType.restingHeartRate)
            }
        }
        .listStyle(.sidebar).frame(minWidth: 200)
        .onChange(of: selectedMetricType) { _, _ in selectedView = .browser; loadData() }
    }

    // MARK: Metrics List
    private var metricsList: some View {
        List(metrics) { metric in
            HStack {
                VStack(alignment: .leading) {
                    Text(metric.date.formatted(date: .abbreviated, time: .shortened)).font(.headline)
                    Text(metric.source).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(metric.displayValue) \(metric.type.unit)")
                    .font(.title3).fontWeight(.semibold)
            }
            .padding(.vertical, 4)
        }
        .listStyle(.inset).frame(minWidth: 300)
        .onChange(of: selectedDateRange) { _, _ in loadData() }
        .overlay {
            if metrics.isEmpty { emptyStateView }
        }
    }

    // MARK: Detail View
    private var detailView: some View {
        Group {
            if metrics.isEmpty {
                emptyStateView
            } else if let metricType = selectedMetricType {
                MetricChartView(metrics: metrics, metricType: metricType)
            }
        }
        .frame(minWidth: 600)
    }

    // MARK: Empty State
    private var emptyStateView: some View {
        Group {
            if !cloudKitAvailable {
                ContentUnavailableView("iCloud Not Available", systemImage: "icloud.slash",
                    description: Text("Sign in to iCloud in System Settings to sync health data"))
            } else if syncStatus.isSyncing {
                VStack(spacing: 16) {
                    ProgressView().scaleEffect(1.5)
                    Text("Syncing from iPhone...").font(.headline)
                    Text("This may take a few moments").font(.caption).foregroundStyle(.secondary)
                }
            } else {
                ContentUnavailableView("No Data Yet", systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Open Health Sync Companion on your iPhone to sync health data"))
            }
        }
    }

    private var cloudKitAvailable: Bool { FileManager.default.ubiquityIdentityToken != nil }

    // MARK: Toolbar Items
    private var dateRangePicker: some View {
        Picker("Date Range", selection: $selectedDateRange) {
            ForEach(DateRange.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }.pickerStyle(.menu)
    }

    private var refreshButton: some View {
        Button {
            syncStatus.startSync()
            Task { try? await Task.sleep(for: .seconds(2)); loadData(); syncStatus.finishSync() }
        } label: { Label("Refresh", systemImage: "arrow.clockwise") }
    }

    private var exportMenu: some View {
        Menu {
            Button { Task { await exportData(format: .csv) } } label: {
                Label("Export as CSV", systemImage: "doc.text")
            }
            Button { Task { await exportData(format: .json) } } label: {
                Label("Export as JSON", systemImage: "doc.badge.gearshape")
            }
        } label: { Label("Export", systemImage: "square.and.arrow.up") }
        .disabled(metrics.isEmpty)
    }

    // MARK: Data Loading
    private func loadData() {
        guard let metricType = selectedMetricType else { return }
        let (start, end) = selectedDateRange.dateRange
        metrics = dataManager.fetchMetrics(from: start, to: end, type: metricType)
    }

    // MARK: Export
    enum ExportFormat { case csv, json }

    @MainActor
    private func exportData(format: ExportFormat) async {
        guard !metrics.isEmpty else { return }
        let dateSuffix = DateFormatter().apply { $0.dateFormat = "yyyy-MM-dd" }.string(from: Date())
        let name = selectedMetricType?.rawValue.replacingOccurrences(of: " ", with: "_") ?? "all"
        let base = "health_\(name)_\(dateSuffix)"

        do {
            let (fileURL, ext): (URL, String) = try {
                switch format {
                case .csv: return (try ExportManager.exportToCSV(metrics: metrics, filename: "\(base).csv"), "csv")
                case .json: return (try ExportManager.exportToJSON(metrics: metrics, filename: "\(base).json"), "json")
                }
            }()
            if let saveURL = await ExportManager.showSavePanel(defaultFilename: "\(base).\(ext)", allowedTypes: [ext]) {
                try FileManager.default.copyItem(at: fileURL, to: saveURL)
            }
        } catch { print("Export error: \(error)") }
    }
}
```

**Step 4.2: App Entry Point**

```swift
// macOS/HealthBrowserApp.swift
import SwiftUI

@main
struct HealthBrowserApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .frame(minWidth: 1000, minHeight: 600)
        }
    }
}
```

---

### Week 2: Visualization, Dashboard & Export (Days 8-14)

---

#### Days 8-9: Swift Charts Visualization

**Step 5.1: MetricChartView**

```swift
// macOS/Views/MetricChartView.swift
import SwiftUI
import Charts

struct MetricChartView: View {
    let metrics: [HealthMetric]
    let metricType: MetricType
    @State private var selectedMetric: HealthMetric?

    private var avgValue: Double {
        guard !metrics.isEmpty else { return 0 }
        return metrics.map(\.value).reduce(0, +) / Double(metrics.count)
    }
    private var maxValue: Double { metrics.map(\.value).max() ?? 0 }
    private var minValue: Double { metrics.map(\.value).min() ?? 0 }
    private var totalValue: Double { metrics.map(\.value).reduce(0, +) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary stat cards
            HStack(spacing: 16) {
                StatCard(title: "Average", value: avgValue, unit: metricType.unit, icon: "chart.bar.fill", color: .blue)
                StatCard(title: "Maximum", value: maxValue, unit: metricType.unit, icon: "arrow.up.circle.fill", color: .green)
                StatCard(title: "Minimum", value: minValue, unit: metricType.unit, icon: "arrow.down.circle.fill", color: .orange)
                if metricType == .steps || metricType == .activeCalories {
                    StatCard(title: "Total", value: totalValue, unit: metricType.unit, icon: "sum", color: .purple)
                }
            }

            // Chart
            Chart {
                ForEach(metrics) { metric in
                    if metricType == .heartRate || metricType == .restingHeartRate {
                        LineMark(x: .value("Date", metric.date), y: .value(metricType.rawValue, metric.value))
                            .foregroundStyle(.blue.gradient).interpolationMethod(.catmullRom)
                        AreaMark(x: .value("Date", metric.date), y: .value(metricType.rawValue, metric.value))
                            .foregroundStyle(.blue.opacity(0.1).gradient).interpolationMethod(.catmullRom)
                    } else {
                        BarMark(x: .value("Date", metric.date, unit: .day), y: .value(metricType.rawValue, metric.value))
                            .foregroundStyle(.blue.gradient)
                    }
                }
                RuleMark(y: .value("Average", avgValue))
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Avg: \(String(format: "%.0f", avgValue))")
                            .font(.caption).foregroundStyle(.green)
                            .padding(4).background(.background)
                    }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel { Text(date.formatted(.dateTime.month(.abbreviated).day())) }
                        AxisGridLine(); AxisTick()
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { AxisValueLabel(); AxisGridLine() }
            }
            .frame(height: 300)
            .overlay(alignment: .topTrailing) {
                if let s = selectedMetric {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(s.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.secondary)
                        Text("\(s.displayValue) \(metricType.unit)").font(.headline)
                        Text(s.source).font(.caption2).foregroundStyle(.tertiary)
                    }
                    .padding(8).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8)).padding()
                }
            }

            // Week comparison
            ComparisonView(
                currentWeekMetrics: currentWeekData,
                previousWeekMetrics: previousWeekData,
                metricType: metricType
            )
        }
        .padding()
    }

    private var currentWeekData: [HealthMetric] {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return metrics.filter { $0.date >= start }
    }

    private var previousWeekData: [HealthMetric] {
        let end = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let start = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        return metrics.filter { $0.date >= start && $0.date < end }
    }
}

struct StatCard: View {
    let title: String; let value: Double; let unit: String; let icon: String; let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.0f", value)).font(.title2).fontWeight(.semibold)
                Text(unit).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
```

**Step 5.2: ComparisonView**

```swift
// macOS/Views/ComparisonView.swift
import SwiftUI
import Charts

struct ComparisonView: View {
    let currentWeekMetrics: [HealthMetric]
    let previousWeekMetrics: [HealthMetric]
    let metricType: MetricType

    private var currentTotal: Double { currentWeekMetrics.map(\.value).reduce(0, +) }
    private var previousTotal: Double { previousWeekMetrics.map(\.value).reduce(0, +) }
    private var pctChange: Double {
        guard previousTotal > 0 else { return 0 }
        return ((currentTotal - previousTotal) / previousTotal) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Week Comparison").font(.title2).fontWeight(.bold)

            HStack(spacing: 16) {
                weekCard(title: "This Week", value: currentTotal, color: .blue)
                weekCard(title: "Last Week", value: previousTotal, color: .gray)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Change").font(.caption).foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image(systemName: pctChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundStyle(pctChange >= 0 ? .green : .red)
                        Text(String(format: "%.1f%%", abs(pctChange)))
                            .font(.title).fontWeight(.bold)
                            .foregroundStyle(pctChange >= 0 ? .green : .red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }

            Chart {
                ForEach(currentWeekMetrics) { metric in
                    BarMark(x: .value("Day", metric.date.formatted(.dateTime.weekday(.abbreviated))),
                            y: .value("Value", metric.value))
                    .foregroundStyle(.blue)
                    .position(by: .value("Period", "This Week"))
                }
                ForEach(previousWeekMetrics) { metric in
                    BarMark(x: .value("Day", metric.date.formatted(.dateTime.weekday(.abbreviated))),
                            y: .value("Value", metric.value))
                    .foregroundStyle(.gray)
                    .position(by: .value("Period", "Last Week"))
                }
            }
            .frame(height: 220)
        }
    }

    private func weekCard(title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.0f", value)).font(.title).fontWeight(.bold).foregroundStyle(color)
                Text(metricType.unit).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
```

---

#### Day 10: Dashboard with Summary Cards

```swift
// macOS/Views/DashboardView.swift
import SwiftUI

struct DashboardView: View {
    @StateObject private var dataManager = DataManager()
    @State private var todayMetrics: DashboardMetrics?
    @State private var weekMetrics: DashboardMetrics?
    @State private var monthMetrics: DashboardMetrics?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Dashboard").font(.largeTitle).fontWeight(.bold).padding(.horizontal)
                summarySection(title: "Today", icon: "calendar", metrics: todayMetrics)
                summarySection(title: "This Week", icon: "calendar.badge.clock", metrics: weekMetrics)
                summarySection(title: "This Month", icon: "calendar.badge.plus", metrics: monthMetrics)
            }
            .padding(.vertical)
        }
        .onAppear { loadDashboardData() }
        .onReceive(NotificationCenter.default.publisher(for: .cloudKitDidSync)) { _ in loadDashboardData() }
    }

    private func summarySection(title: String, icon: String, metrics: DashboardMetrics?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).font(.title2).fontWeight(.semibold).padding(.horizontal)

            if let m = metrics {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MetricCard(title: "Steps",          value: m.steps,            unit: "steps",   icon: "figure.walk",    color: .blue)
                    MetricCard(title: "Active Calories", value: m.activeCalories,   unit: "kcal",    icon: "flame.fill",     color: .orange)
                    MetricCard(title: "Avg Heart Rate",  value: m.avgHeartRate,     unit: "bpm",     icon: "heart.fill",     color: .red)
                    MetricCard(title: "Workouts",        value: Double(m.workoutCount), unit: "sessions", icon: "figure.run", color: .green)
                    MetricCard(title: "Exercise Time",   value: m.exerciseMinutes,  unit: "min",     icon: "timer",          color: .purple)
                    MetricCard(title: "Resting HR",      value: m.restingHeartRate, unit: "bpm",     icon: "heart.circle",   color: .pink)
                }
                .padding(.horizontal)
            } else {
                ProgressView().frame(maxWidth: .infinity).padding()
            }
        }
    }

    private func loadDashboardData() {
        let cal = Calendar.current, now = Date()
        todayMetrics  = metrics(from: cal.startOfDay(for: now), to: now)
        weekMetrics   = metrics(from: cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!, to: now)
        monthMetrics  = metrics(from: cal.date(from: cal.dateComponents([.year, .month], from: now))!, to: now)
    }

    private func metrics(from start: Date, to end: Date) -> DashboardMetrics {
        let steps    = dataManager.fetchMetrics(from: start, to: end, type: .steps).map(\.value).reduce(0, +)
        let cals     = dataManager.fetchMetrics(from: start, to: end, type: .activeCalories).map(\.value).reduce(0, +)
        let hr       = dataManager.fetchMetrics(from: start, to: end, type: .heartRate).map(\.value)
        let rhr      = dataManager.fetchMetrics(from: start, to: end, type: .restingHeartRate).last?.value ?? 0
        return DashboardMetrics(
            steps: steps, activeCalories: cals,
            avgHeartRate: hr.isEmpty ? 0 : hr.reduce(0, +) / Double(hr.count),
            restingHeartRate: rhr, workoutCount: 0, exerciseMinutes: 0
        )
    }
}

struct DashboardMetrics {
    let steps, activeCalories, avgHeartRate, restingHeartRate, exerciseMinutes: Double
    let workoutCount: Int
}

struct MetricCard: View {
    let title: String; let value: Double; let unit: String; let icon: String; let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.0f", value)).font(.title).fontWeight(.bold)
                    Text(unit).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
    }
}
```

---

#### Days 11-12: Export Manager

```swift
// Shared/ExportManager.swift
import Foundation
import AppKit
import UniformTypeIdentifiers

class ExportManager {

    static func exportToCSV(metrics: [HealthMetric], filename: String) throws -> URL {
        var csv = "Date,Metric Type,Value,Unit,Source\n"
        let fmt = ISO8601DateFormatter()
        for m in metrics {
            csv += "\(fmt.string(from: m.date)),\(m.type.rawValue),\(m.value),\(m.type.unit),\"\(m.source)\"\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func exportToJSON(metrics: [HealthMetric], filename: String) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try encoder.encode(metrics).write(to: url)
        return url
    }

    @MainActor
    static func showSavePanel(defaultFilename: String, allowedTypes: [String]) async -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultFilename
        panel.allowedContentTypes = allowedTypes.compactMap { UTType(filenameExtension: $0) }
        panel.canCreateDirectories = true
        return await panel.begin() == .OK ? panel.url : nil
    }
}

// DateFormatter convenience
extension DateFormatter {
    func apply(_ block: (DateFormatter) -> Void) -> DateFormatter {
        block(self); return self
    }
}
```

---

#### Days 13-14: Sync Status and Polish

```swift
// macOS/Views/SyncStatusView.swift
import SwiftUI

struct SyncStatusView: View {
    @ObservedObject var syncManager: SyncStatusManager

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: syncManager.icon).foregroundStyle(syncManager.color)
            Text(syncManager.statusText).font(.caption).foregroundStyle(.secondary)
            if syncManager.isSyncing { ProgressView().scaleEffect(0.7) }
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(.regularMaterial, in: Capsule())
    }
}

@MainActor
class SyncStatusManager: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?

    var statusText: String {
        if syncError != nil { return "Sync failed" }
        if isSyncing { return "Syncing..." }
        if let d = lastSyncDate { return "Updated \(d.formatted(.relative(presentation: .named)))" }
        return "Not synced"
    }

    var icon: String {
        syncError != nil ? "exclamationmark.icloud" : isSyncing ? "icloud.and.arrow.down" : "icloud"
    }

    var color: Color {
        syncError != nil ? .red : isSyncing ? .blue : .green
    }

    func startSync() { isSyncing = true; syncError = nil }
    func finishSync(error: Error? = nil) {
        isSyncing = false; syncError = error
        if error == nil { lastSyncDate = Date() }
    }
}
```

---

## Week 2 Deliverables Checklist

- [ ] Interactive Swift Charts: line (heart rate), bar (steps/calories), area fill, average rule line
- [ ] Stat cards: average, max, min, total per selected date range
- [ ] Week-over-week comparison chart with percentage change
- [ ] Dashboard view: today / this week / this month summaries with MetricCard grid
- [ ] CSV export with ISO8601 dates and NSSavePanel
- [ ] JSON export with pretty-printed Codable output
- [ ] Sync status pill in toolbar (iCloud icon + relative date + spinner)
- [ ] CloudKit push notifications trigger UI refresh automatically
- [ ] Manual refresh button
- [ ] Contextual empty states (no iCloud, syncing, no data yet)

---

## Week 3: TestFlight & Iteration

- Create App Store Connect entries for both iOS and macOS apps
- Upload TestFlight builds (iOS + macOS)
- Recruit 10-20 beta testers: Reddit (r/apple, r/AppleWatch, r/rowing), Twitter/X, Indie Hackers
- Survey: most-used metrics, missing features, pain points
- Fix critical bugs, add top 1-2 requested features
- Prepare App Store screenshots and preview video

---

## Monetization Strategy

| Model | Price | Target |
|-------|-------|--------|
| One-time purchase | $10-20 | Casual users |
| Freemium | Free + $5/month | Power users, premium features |
| Lifetime unlock | $50-80 | Early adopters |

**Conservative Year 1:** 1,000 users × $10 + 100 subs × $5/mo = **$16,000**
**Optimistic Year 1:** 10,000 users × $15 + 1,000 subs × $5/mo = **$210,000**

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| CloudKit sync unreliable | High | Add local network sync fallback (Multipeer) |
| Apple launches native app | Critical | Pivot to premium ML features Apple won't build |
| Low user adoption | Medium | Focus on rowing niche first, expand later |
| Data privacy concerns | High | Emphasize local processing, no cloud servers |
| HealthKit API changes | Medium | Monitor WWDC, maintain compatibility |

---

## Success Metrics

**POC (Week 1-3):** 5+ metrics syncing, <2s latency, 0 critical bugs, 10+ beta testers

**Launch (Month 1-3):** 500+ downloads, 4.0+ App Store rating, 10% paid conversion, 50+ reviews

**Growth (Month 4-12):** 5,000+ active users, $50k+ revenue, MacStories/9to5Mac coverage

---

## References

1. [HealthKit availability on macOS — Stack Overflow](https://stackoverflow.com/questions/75257266/healthkit-availability-on-macos)
2. [Heal - SwiftUI HealthKit App — GitHub](https://github.com/Mohamed26Salah/Heal)
3. [Reading data from HealthKit in a SwiftUI app — Create with Swift](https://www.createwithswift.com/reading-data-from-healthkit-in-a-swiftui-app/)
4. [How to Export Your Apple Health Data — applehealthdata.com](https://applehealthdata.com/export-apple-health-data/)
5. [Apple HealthKit API Integration — Terra API](https://tryterra.co/integrations/apple-health)
6. [Apple Health App on macOS — Reddit r/MacOS](https://www.reddit.com/r/MacOS/comments/1jy1bj4/apple_health_app_on_macos_why_dont_we_have_it_yet/)
7. [SwiftUI Building a Health App with HealthKit — YouTube](https://www.youtube.com/watch?v=ORJ9rvqoR9s)
8. [HealthKit Integration with SwiftUI Full Code — YouTube](https://www.youtube.com/watch?v=ihcWCb6B-B0)
