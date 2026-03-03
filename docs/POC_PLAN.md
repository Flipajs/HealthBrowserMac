# macOS Health Data Browser - POC Development Plan

This document contains the complete Proof of Concept (POC) development plan for HealthBrowser for macOS. It was generated from comprehensive market research and technical analysis.

## Executive Summary

Apple does not provide native HealthKit support for macOS applications, despite the framework being present in the SDK. This creates a significant market opportunity for a third-party health data browser that syncs iPhone Health data to Mac for browsing, analysis, and visualization.

**Target POC Timeline:** 2-3 weeks for MVP with core browsing capabilities.

**Revenue Potential:** 10,000 users at $10-20 one-time purchase = $100-200k annual revenue, scalable to subscription model ($2-5/month) for premium features.

## Technical Constraints

### HealthKit macOS Reality

- HealthKit framework exists in macOS SDK (macOS 13.0+) but `HKHealthStore.isHealthDataAvailable()` returns `false` on Mac
- **No direct HealthKit access on macOS** - data syncing must happen via alternative methods
- iPhone/iPad HealthKit APIs fully functional for iOS apps

### Chosen Architecture: iOS Companion + CloudKit

**Why this approach:**
1. **Privacy-preserving**: All data stays in user's iCloud account
2. **Automatic sync**: CloudKit handles sync automatically via NSPersistentCloudKitContainer
3. **Native integration**: Uses official Apple frameworks (no third-party services)
4. **Reliable**: CloudKit has 99.95% uptime SLA
5. **Simple**: No custom networking code required

**Alternative approaches considered:**
- ❌ XML export parsing: One-time only, no live sync, poor UX
- ❌ Third-party APIs (Terra): Privacy concerns, external dependencies
- ❌ Local network sync (Bonjour): Complex, requires both devices on same network

## Implementation Timeline

### Week 1: Foundation (Day 1-7)

#### Day 1-2: Project Setup
- [x] Create GitHub repository
- [ ] Initialize Xcode workspace
- [ ] Configure CloudKit container
- [ ] Set up App Groups for shared data
- [ ] Add HealthKit capability to iOS target

#### Day 3-4: iOS HealthKit Integration
- [ ] Implement `HealthKitManager.swift`
- [ ] Request authorization for 5 core metrics
- [ ] Fetch sample data: steps, heart rate, workouts, calories, sleep
- [ ] Test on physical iPhone (required for real Health data)

#### Day 5-7: CoreData + CloudKit Sync
- [ ] Design CoreData schema (`HealthMetric` entity)
- [ ] Enable NSPersistentCloudKitContainer
- [ ] Implement data saving from HealthKit to CoreData
- [ ] Verify CloudKit sync between iOS and Mac

### Week 2: macOS App (Day 8-14)

#### Day 8-10: Browser UI
- [ ] Build NavigationSplitView layout
- [ ] Implement sidebar with metric categories
- [ ] Create list view for time-series data
- [ ] Add detail pane for individual metrics
- [ ] Date range picker in toolbar

#### Day 11-12: Visualizations
- [ ] Integrate Swift Charts framework
- [ ] Line chart for steps/heart rate trends
- [ ] Bar chart for workout durations
- [ ] Summary cards (daily/weekly aggregates)

#### Day 13-14: Export & Polish
- [ ] CSV export with NSSavePanel
- [ ] JSON export with pretty-printing
- [ ] Loading states and error handling
- [ ] Empty states ("Sync from iPhone")

### Week 3: Testing & Refinement (Day 15-21)

#### Day 15-17: Beta Testing
- [ ] Create App Store Connect entries
- [ ] Upload to TestFlight (iOS + macOS)
- [ ] Recruit 10-20 beta testers
- [ ] Set up feedback collection (survey + GitHub issues)

#### Day 18-21: Iteration
- [ ] Fix critical bugs from beta feedback
- [ ] Implement 1-2 most-requested features
- [ ] Final UI polish
- [ ] Prepare App Store screenshots and description

## Core Features Checklist

### Must-Have (MVP)

- [ ] **iOS HealthKit Authorization**
  - Steps
  - Heart Rate (resting and active)
  - Workouts (type, duration, calories)
  - Active Energy (calories burned)
  - Sleep Analysis

- [ ] **CloudKit Sync**
  - Automatic background sync
  - Conflict resolution (last-write-wins)
  - Sync status indicator

- [ ] **macOS Browser**
  - Three-pane layout (sidebar, list, detail)
  - Metric categories navigation
  - Date range filtering
  - Search functionality

- [ ] **Visualizations**
  - Line charts (time-series)
  - Bar charts (aggregates)
  - Summary cards (totals, averages)

- [ ] **Export**
  - CSV format
  - JSON format
  - Date range selection for export

### Nice-to-Have (Phase 2)

- [ ] Heatmap visualizations
- [ ] Correlation analysis
- [ ] Rowing workout details
- [ ] Custom dashboard layouts
- [ ] PDF report generation
- [ ] Goal tracking

### Premium (Phase 3)

- [ ] Local AI analysis (Ollama)
- [ ] Anomaly detection
- [ ] Predictive models
- [ ] Natural language queries
- [ ] Strava integration
- [ ] Training Peaks export

## Technical Implementation Details

### HealthKit Data Types Priority

**Tier 1 (Implement First):**
```swift
let healthKitTypes: Set<HKSampleType> = [
    HKQuantityType.quantityType(forIdentifier: .stepCount)!,
    HKQuantityType.quantityType(forIdentifier: .heartRate)!,
    HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
    HKObjectType.workoutType(),
    HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
]
```

**Tier 2 (Add Later):**
- Heart Rate Variability (HRV)
- Resting Heart Rate
- VO2 Max
- Blood Oxygen
- Respiratory Rate
- Body Temperature

**Tier 3 (Rowing Specialization):**
- Workout Route (GPS data)
- Rowing Distance
- Rowing Stroke Count
- Rowing Power

### CoreData Schema

```swift
// HealthMetric Entity
@objc(HealthMetric)
public class HealthMetric: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var type: String // "steps", "heartRate", etc.
    @NSManaged public var value: Double
    @NSManaged public var date: Date
    @NSManaged public var source: String // "Apple Watch", "iPhone"
    @NSManaged public var unit: String // "count", "bpm", "kcal"
    @NSManaged public var metadata: Data? // JSON for extra info
    @NSManaged public var syncedAt: Date
}

// Workout Entity
@objc(Workout)
public class Workout: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var type: String // "Rowing", "Running", etc.
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var duration: TimeInterval
    @NSManaged public var totalDistance: Double?
    @NSManaged public var totalEnergyBurned: Double?
    @NSManaged public var metadata: Data?
    @NSManaged public var syncedAt: Date
}
```

### CloudKit Configuration

**Container Identifier:**
```
iCloud.com.filipnaiser.HealthBrowser
```

**App Group:**
```
group.com.filipnaiser.HealthBrowser
```

**Sync Strategy:**
- Use `NSPersistentCloudKitContainer` for automatic sync
- Enable CloudKit in both iOS and macOS targets
- Use same CloudKit container and app group
- Let CoreData handle sync automatically (no manual CKRecord management)

### Swift Charts Examples

**Line Chart (Steps Over Time):**
```swift
Chart(metrics) { metric in
    LineMark(
        x: .value("Date", metric.date),
        y: .value("Steps", metric.value)
    )
    .foregroundStyle(.blue)
    .interpolationMethod(.catmullRom)
}
.chartXAxis {
    AxisMarks(values: .stride(by: .day)) { _ in
        AxisGridLine()
        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
    }
}
.chartYAxis {
    AxisMarks(position: .leading)
}
.frame(height: 300)
```

**Bar Chart (Workout Durations):**
```swift
Chart(workouts) { workout in
    BarMark(
        x: .value("Type", workout.type),
        y: .value("Duration", workout.duration / 60)
    )
    .foregroundStyle(by: .value("Type", workout.type))
}
.chartYAxis {
    AxisMarks { _ in
        AxisValueLabel(format: .number.notation(.compactName))
    }
}
.chartYAxisLabel("Minutes")
```

## Testing Strategy

### Unit Tests
- [ ] HealthKitManager: Authorization and query methods
- [ ] DataManager: CoreData CRUD operations
- [ ] Export: CSV/JSON serialization
- [ ] ChartViewModel: Data aggregation logic

### Integration Tests
- [ ] CloudKit sync: Save on iOS, verify on macOS
- [ ] Data integrity: Verify values match HealthKit source
- [ ] Sync latency: Measure time from iOS save to macOS fetch

### UI Tests
- [ ] Navigation flow: Sidebar → List → Detail
- [ ] Chart rendering: Verify charts display correctly
- [ ] Export flow: Save file dialog and file creation

### Beta Testing Scenarios
- [ ] Fresh install on new device (no data)
- [ ] Existing Health data (multiple years)
- [ ] Sync with limited internet (3G/4G)
- [ ] Multiple devices (iPhone + iPad → Mac)
- [ ] Different metric combinations

## Success Metrics

### POC Phase (Week 1-3)
- ✅ 5+ core metrics syncing reliably
- ✅ <5 second sync latency for new data
- ✅ 0 critical bugs in TestFlight
- ✅ 10+ beta testers providing feedback
- ✅ Positive feedback on UX and performance

### Launch Phase (Month 1-3)
- 500+ downloads in first month
- 4.0+ star rating on App Store
- 10% conversion to paid (if freemium)
- 50+ user reviews/testimonials
- <1% crash rate

### Growth Phase (Month 4-12)
- 5,000+ active users
- $50k+ revenue
- Feature parity with Health.md and Health Auto Export
- 1-2 press mentions (MacStories, 9to5Mac)
- Establish niche dominance in rowing/fitness community

## Risk Mitigation

### Technical Risks

**CloudKit sync unreliability**
- Mitigation: Add local network sync fallback using Multipeer Connectivity
- Fallback: Allow manual export/import via files

**HealthKit API changes**
- Mitigation: Monitor WWDC annually, maintain backward compatibility
- Fallback: Keep supporting older iOS versions for 2+ years

**Data privacy concerns**
- Mitigation: Emphasize local processing, no third-party servers
- Marketing: "Your data never leaves your devices or iCloud"

### Market Risks

**Apple launches native macOS Health app**
- Mitigation: Pivot to advanced features Apple won't build (ML analysis, rowing focus)
- Timing: Monitor Apple announcements, be ready to adapt

**Low user adoption**
- Mitigation: Start with rowing niche (smaller, passionate community)
- Expansion: Gradually expand to general fitness users

**Competition from existing apps**
- Differentiation: Focus on UX polish, ML features, rowing specialization
- Pricing: Competitive pricing with generous free tier

## Next Steps

### Immediate Actions (Today)

1. ✅ Create GitHub repository
2. [ ] Create Xcode workspace with iOS and macOS targets
3. [ ] Configure CloudKit container in Apple Developer portal
4. [ ] Set up App Group identifier
5. [ ] Add HealthKit capability to iOS target
6. [ ] Initialize CoreData model with HealthMetric entity

### This Week

1. [ ] Implement HealthKitManager.swift with authorization
2. [ ] Test HealthKit queries on physical iPhone
3. [ ] Set up NSPersistentCloudKitContainer
4. [ ] Verify CloudKit sync between iOS simulator and Mac

### Next Week

1. [ ] Build macOS NavigationSplitView UI
2. [ ] Implement Swift Charts for basic line graph
3. [ ] Add CSV export functionality
4. [ ] Prepare TestFlight builds

---

**Last Updated:** March 3, 2026
**Version:** 1.0
**Author:** Filip Naiser