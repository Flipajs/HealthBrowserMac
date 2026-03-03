//
//  HealthKitManager.swift
//  HealthBrowseriOS
//
//  Created on 2026-03-03
//

import Foundation
import HealthKit
import Combine

/// Manages all HealthKit authorization and data queries
/// Supports background queries and observer patterns for real-time updates
class HealthKitManager: ObservableObject {
    
    private let healthStore = HKHealthStore()
    
    // MARK: - Health Data Types
    
    /// Core metrics to sync (Phase 1)
    private let readTypes: Set<HKSampleType> = [
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.workoutType(),
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    ]
    
    // MARK: - Authorization
    
    /// Check if HealthKit is available on this device
    func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    /// Request authorization to read health data
    func requestAuthorization() async throws {
        guard isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }
    
    // MARK: - Data Fetching
    
    /// Fetch step count for a specific date range
    func fetchSteps(startDate: Date, endDate: Date) async throws -> [HealthMetricData] {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.invalidType
        }
        
        return try await fetchQuantityData(
            type: stepType,
            unit: .count(),
            startDate: startDate,
            endDate: endDate,
            metricType: "steps"
        )
    }
    
    /// Fetch heart rate samples for a specific date range
    func fetchHeartRate(startDate: Date, endDate: Date) async throws -> [HealthMetricData] {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.invalidType
        }
        
        return try await fetchQuantityData(
            type: hrType,
            unit: HKUnit(from: "count/min"),
            startDate: startDate,
            endDate: endDate,
            metricType: "heartRate"
        )
    }
    
    /// Fetch resting heart rate for a specific date range
    func fetchRestingHeartRate(startDate: Date, endDate: Date) async throws -> [HealthMetricData] {
        guard let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            throw HealthKitError.invalidType
        }
        
        return try await fetchQuantityData(
            type: restingHRType,
            unit: HKUnit(from: "count/min"),
            startDate: startDate,
            endDate: endDate,
            metricType: "restingHeartRate"
        )
    }
    
    /// Fetch active energy burned for a specific date range
    func fetchActiveEnergy(startDate: Date, endDate: Date) async throws -> [HealthMetricData] {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.invalidType
        }
        
        return try await fetchQuantityData(
            type: energyType,
            unit: .kilocalorie(),
            startDate: startDate,
            endDate: endDate,
            metricType: "activeEnergy"
        )
    }
    
    /// Fetch workouts for a specific date range
    func fetchWorkouts(startDate: Date, endDate: Date) async throws -> [WorkoutData] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let workoutData = workouts.map { workout in
                    WorkoutData(
                        id: workout.uuid,
                        type: workout.workoutActivityType.name,
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        duration: workout.duration,
                        totalDistance: workout.totalDistance?.doubleValue(for: .meter()),
                        totalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
                        source: workout.sourceRevision.source.name
                    )
                }
                
                continuation.resume(returning: workoutData)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetch sleep analysis for a specific date range
    func fetchSleep(startDate: Date, endDate: Date) async throws -> [SleepData] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.invalidType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let sleepData = sleepSamples.map { sample in
                    SleepData(
                        id: sample.uuid,
                        startDate: sample.startDate,
                        endDate: sample.endDate,
                        value: sample.value,
                        source: sample.sourceRevision.source.name
                    )
                }
                
                continuation.resume(returning: sleepData)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Generic Quantity Fetcher
    
    private func fetchQuantityData(
        type: HKQuantityType,
        unit: HKUnit,
        startDate: Date,
        endDate: Date,
        metricType: String
    ) async throws -> [HealthMetricData] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let metrics = quantitySamples.map { sample in
                    HealthMetricData(
                        id: sample.uuid,
                        type: metricType,
                        value: sample.quantity.doubleValue(for: unit),
                        date: sample.startDate,
                        source: sample.sourceRevision.source.name,
                        unit: unit.unitString
                    )
                }
                
                continuation.resume(returning: metrics)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Background Observer
    
    /// Set up background observer for new health data
    /// This enables real-time sync when new data arrives
    func setupBackgroundObserver(for types: [HKSampleType], completion: @escaping () -> Void) {
        for type in types {
            let query = HKObserverQuery(sampleType: type, predicate: nil) { _, _, error in
                if let error = error {
                    print("Observer query error: \(error.localizedDescription)")
                    return
                }
                
                // Trigger sync when new data arrives
                completion()
            }
            
            healthStore.execute(query)
            
            // Enable background delivery
            healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
                if let error = error {
                    print("Background delivery error: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Data Models

struct HealthMetricData: Identifiable {
    let id: UUID
    let type: String
    let value: Double
    let date: Date
    let source: String
    let unit: String
}

struct WorkoutData: Identifiable {
    let id: UUID
    let type: String
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let totalDistance: Double?
    let totalEnergyBurned: Double?
    let source: String
}

struct SleepData: Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let value: Int // HKCategoryValueSleepAnalysis raw value
    let source: String
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case invalidType
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .invalidType:
            return "Invalid HealthKit data type"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        }
    }
}

// MARK: - Extensions

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .rowing: return "Rowing"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .walking: return "Walking"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Strength Training"
        case .coreTraining: return "Core Training"
        case .elliptical: return "Elliptical"
        case .stairClimbing: return "Stair Climbing"
        case .hiit: return "HIIT"
        default: return "Other"
        }
    }
}
