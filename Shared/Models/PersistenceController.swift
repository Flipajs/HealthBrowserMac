//
//  PersistenceController.swift
//  HealthBrowser
//
//  Created on 2026-03-03
//

import CoreData
import CloudKit

/// Manages CoreData persistence with CloudKit sync
struct PersistenceController {
    static let shared = PersistenceController()
    
    // Preview instance for SwiftUI previews
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        for i in 0..<10 {
            let metric = HealthMetric(context: viewContext)
            metric.id = UUID()
            metric.type = "steps"
            metric.value = Double.random(in: 5000...15000)
            metric.date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            metric.source = "Apple Watch"
            metric.unit = "count"
            metric.syncedAt = Date()
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "HealthBrowser")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure CloudKit container
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve persistent store description")
            }
            
            // Enable persistent history tracking for CloudKit sync
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // Configure CloudKit container options
            let cloudKitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.filipnaiser.HealthBrowser")
            description.cloudKitContainerOptions = cloudKitOptions
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Replace this with proper error handling in production
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Automatically merge changes from parent
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Set up notifications for remote changes
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { _ in
            print("Remote CloudKit changes detected")
        }
    }
    
    // MARK: - Save Context
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Batch Operations
    
    /// Save multiple health metrics efficiently
    func saveHealthMetrics(_ metrics: [HealthMetricData]) async throws {
        let context = container.newBackgroundContext()
        
        try await context.perform {
            for metricData in metrics {
                // Check if metric already exists
                let fetchRequest: NSFetchRequest<HealthMetric> = HealthMetric.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", metricData.id as CVarArg)
                
                let existingMetrics = try context.fetch(fetchRequest)
                
                if existingMetrics.isEmpty {
                    let metric = HealthMetric(context: context)
                    metric.id = metricData.id
                    metric.type = metricData.type
                    metric.value = metricData.value
                    metric.date = metricData.date
                    metric.source = metricData.source
                    metric.unit = metricData.unit
                    metric.syncedAt = Date()
                }
            }
            
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    /// Save multiple workouts efficiently
    func saveWorkouts(_ workouts: [WorkoutData]) async throws {
        let context = container.newBackgroundContext()
        
        try await context.perform {
            for workoutData in workouts {
                // Check if workout already exists
                let fetchRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", workoutData.id as CVarArg)
                
                let existingWorkouts = try context.fetch(fetchRequest)
                
                if existingWorkouts.isEmpty {
                    let workout = Workout(context: context)
                    workout.id = workoutData.id
                    workout.type = workoutData.type
                    workout.startDate = workoutData.startDate
                    workout.endDate = workoutData.endDate
                    workout.duration = workoutData.duration
                    workout.totalDistance = workoutData.totalDistance ?? 0
                    workout.totalEnergyBurned = workoutData.totalEnergyBurned ?? 0
                    workout.source = workoutData.source
                    workout.syncedAt = Date()
                }
            }
            
            if context.hasChanges {
                try context.save()
            }
        }
    }
}
