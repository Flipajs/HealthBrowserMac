//
//  ContentView.swift
//  HealthBrowseriOS
//
//  Created on 2026-03-03
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var healthManager = HealthKitManager()
    @StateObject private var syncManager = SyncManager()
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.pink)
                    
                    Text("HealthBrowser")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sync your health data to Mac")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Status Card
                StatusCardView(syncManager: syncManager)
                
                // Metrics Summary
                MetricsSummaryView(syncManager: syncManager)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 15) {
                    if !syncManager.isAuthorized {
                        Button(action: {
                            Task {
                                await syncManager.requestAuthorization()
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                Text("Authorize HealthKit")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    } else {
                        Button(action: {
                            Task {
                                await syncManager.syncAllData()
                            }
                        }) {
                            HStack {
                                if syncManager.isSyncing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                Text(syncManager.isSyncing ? "Syncing..." : "Sync Now")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(syncManager.isSyncing ? Color.gray : Color.pink)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(syncManager.isSyncing)
                        
                        Toggle("Auto-Sync", isOn: $syncManager.autoSyncEnabled)
                            .padding(.horizontal)
                            .tint(.pink)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            // Check authorization on app launch
            await syncManager.checkAuthorizationStatus()
            
            // Setup background observer if authorized
            if syncManager.isAuthorized {
                syncManager.setupBackgroundSync()
            }
        }
    }
}

struct StatusCardView: View {
    @ObservedObject var syncManager: SyncManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(syncManager.syncStatus == .synced ? Color.green : 
                          syncManager.syncStatus == .syncing ? Color.orange : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(syncManager.syncStatus.description)
                    .font(.headline)
                
                Spacer()
                
                if let lastSync = syncManager.lastSyncDate {
                    Text(lastSync, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let error = syncManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
        .padding(.horizontal, 30)
    }
}

struct MetricsSummaryView: View {
    @ObservedObject var syncManager: SyncManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Synced Data")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                MetricCardView(
                    icon: "figure.walk",
                    title: "Steps",
                    value: syncManager.syncedMetrics["steps"] ?? 0,
                    color: .blue
                )
                
                MetricCardView(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    value: syncManager.syncedMetrics["heartRate"] ?? 0,
                    color: .red
                )
                
                MetricCardView(
                    icon: "flame.fill",
                    title: "Calories",
                    value: syncManager.syncedMetrics["activeEnergy"] ?? 0,
                    color: .orange
                )
                
                MetricCardView(
                    icon: "dumbbell.fill",
                    title: "Workouts",
                    value: syncManager.syncedMetrics["workouts"] ?? 0,
                    color: .green
                )
            }
        }
        .padding(.horizontal, 30)
    }
}

struct MetricCardView: View {
    let icon: String
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }
}

// MARK: - Sync Manager

class SyncManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var isSyncing = false
    @Published var syncStatus: SyncStatus = .notSynced
    @Published var lastSyncDate: Date?
    @Published var lastError: String?
    @Published var autoSyncEnabled = true {
        didSet {
            UserDefaults.standard.set(autoSyncEnabled, forKey: "autoSyncEnabled")
            if autoSyncEnabled {
                setupBackgroundSync()
            }
        }
    }
    @Published var syncedMetrics: [String: Int] = [:]
    
    private let healthManager = HealthKitManager()
    private let persistence = PersistenceController.shared
    
    init() {
        self.autoSyncEnabled = UserDefaults.standard.bool(forKey: "autoSyncEnabled")
    }
    
    func checkAuthorizationStatus() async {
        await MainActor.run {
            isAuthorized = healthManager.isHealthDataAvailable()
        }
    }
    
    func requestAuthorization() async {
        do {
            try await healthManager.requestAuthorization()
            await MainActor.run {
                isAuthorized = true
                lastError = nil
            }
            
            // Perform initial sync after authorization
            await syncAllData()
        } catch {
            await MainActor.run {
                lastError = "Authorization failed: \(error.localizedDescription)"
            }
        }
    }
    
    func syncAllData() async {
        guard !isSyncing else { return }
        
        await MainActor.run {
            isSyncing = true
            syncStatus = .syncing
            lastError = nil
        }
        
        do {
            // Fetch last 90 days of data
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -90, to: endDate)!
            
            // Fetch all metrics in parallel
            async let stepsData = healthManager.fetchSteps(startDate: startDate, endDate: endDate)
            async let heartRateData = healthManager.fetchHeartRate(startDate: startDate, endDate: endDate)
            async let restingHRData = healthManager.fetchRestingHeartRate(startDate: startDate, endDate: endDate)
            async let energyData = healthManager.fetchActiveEnergy(startDate: startDate, endDate: endDate)
            async let workoutsData = healthManager.fetchWorkouts(startDate: startDate, endDate: endDate)
            
            let (steps, heartRate, restingHR, energy, workouts) = try await (
                stepsData, heartRateData, restingHRData, energyData, workoutsData
            )
            
            // Save to CoreData
            let allMetrics = steps + heartRate + restingHR + energy
            try await persistence.saveHealthMetrics(allMetrics)
            try await persistence.saveWorkouts(workouts)
            
            // Update synced counts
            await MainActor.run {
                syncedMetrics["steps"] = steps.count
                syncedMetrics["heartRate"] = heartRate.count + restingHR.count
                syncedMetrics["activeEnergy"] = energy.count
                syncedMetrics["workouts"] = workouts.count
                
                isSyncing = false
                syncStatus = .synced
                lastSyncDate = Date()
            }
            
            print("✅ Sync completed: \(allMetrics.count) metrics, \(workouts.count) workouts")
        } catch {
            await MainActor.run {
                isSyncing = false
                syncStatus = .error
                lastError = "Sync failed: \(error.localizedDescription)"
            }
            print("❌ Sync error: \(error)")
        }
    }
    
    func setupBackgroundSync() {
        guard autoSyncEnabled else { return }
        
        let types: [HKSampleType] = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType()
        ]
        
        healthManager.setupBackgroundObserver(for: types) {
            Task {
                await self.syncAllData()
            }
        }
        
        print("📡 Background sync enabled")
    }
}

enum SyncStatus {
    case notSynced
    case syncing
    case synced
    case error
    
    var description: String {
        switch self {
        case .notSynced: return "Not Synced"
        case .syncing: return "Syncing..."
        case .synced: return "Synced"
        case .error: return "Sync Error"
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
