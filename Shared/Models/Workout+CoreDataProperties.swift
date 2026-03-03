//
//  Workout+CoreDataProperties.swift
//  HealthBrowser
//
//  Created on 2026-03-03
//

import Foundation
import CoreData

extension Workout {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Workout> {
        return NSFetchRequest<Workout>(entityName: "Workout")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var duration: TimeInterval
    @NSManaged public var totalDistance: Double
    @NSManaged public var totalEnergyBurned: Double
    @NSManaged public var source: String?
    @NSManaged public var metadata: Data?
    @NSManaged public var syncedAt: Date?
    
}

extension Workout: Identifiable {
    
}
