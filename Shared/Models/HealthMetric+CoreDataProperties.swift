//
//  HealthMetric+CoreDataProperties.swift
//  HealthBrowser
//
//  Created on 2026-03-03
//

import Foundation
import CoreData

extension HealthMetric {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<HealthMetric> {
        return NSFetchRequest<HealthMetric>(entityName: "HealthMetric")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var value: Double
    @NSManaged public var date: Date?
    @NSManaged public var source: String?
    @NSManaged public var unit: String?
    @NSManaged public var metadata: Data?
    @NSManaged public var syncedAt: Date?
    
}

extension HealthMetric: Identifiable {
    
}
