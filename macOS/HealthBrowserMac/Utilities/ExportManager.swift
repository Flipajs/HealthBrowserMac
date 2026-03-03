//
//  ExportManager.swift
//  HealthBrowserMac
//
//  Created on 2026-03-03
//

import Foundation
import AppKit
import CoreData

class ExportManager {
    
    enum ExportFormat {
        case csv
        case json
    }
    
    enum ExportError: LocalizedError {
        case noData
        case exportFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .noData:
                return "No data available to export"
            case .exportFailed(let reason):
                return "Export failed: \(reason)"
            }
        }
    }
    
    // MARK: - Export Health Metrics
    
    static func exportMetrics(
        _ metrics: [HealthMetric],
        format: ExportFormat,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard !metrics.isEmpty else {
            completion(.failure(ExportError.noData))
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "health_metrics_\(Date().ISO8601Format())"
        savePanel.canCreateDirectories = true
        
        switch format {
        case .csv:
            savePanel.allowedContentTypes = [.commaSeparatedText]
            savePanel.begin { response in
                guard response == .OK, let url = savePanel.url else {
                    completion(.failure(ExportError.exportFailed("User cancelled")))
                    return
                }
                
                do {
                    let csvString = try createCSV(from: metrics)
                    try csvString.write(to: url, atomically: true, encoding: .utf8)
                    completion(.success(url))
                } catch {
                    completion(.failure(error))
                }
            }
            
        case .json:
            savePanel.allowedContentTypes = [.json]
            savePanel.begin { response in
                guard response == .OK, let url = savePanel.url else {
                    completion(.failure(ExportError.exportFailed("User cancelled")))
                    return
                }
                
                do {
                    let jsonData = try createJSON(from: metrics)
                    try jsonData.write(to: url)
                    completion(.success(url))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Export Workouts
    
    static func exportWorkouts(
        _ workouts: [Workout],
        format: ExportFormat,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard !workouts.isEmpty else {
            completion(.failure(ExportError.noData))
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "workouts_\(Date().ISO8601Format())"
        savePanel.canCreateDirectories = true
        
        switch format {
        case .csv:
            savePanel.allowedContentTypes = [.commaSeparatedText]
            savePanel.begin { response in
                guard response == .OK, let url = savePanel.url else {
                    completion(.failure(ExportError.exportFailed("User cancelled")))
                    return
                }
                
                do {
                    let csvString = try createWorkoutCSV(from: workouts)
                    try csvString.write(to: url, atomically: true, encoding: .utf8)
                    completion(.success(url))
                } catch {
                    completion(.failure(error))
                }
            }
            
        case .json:
            savePanel.allowedContentTypes = [.json]
            savePanel.begin { response in
                guard response == .OK, let url = savePanel.url else {
                    completion(.failure(ExportError.exportFailed("User cancelled")))
                    return
                }
                
                do {
                    let jsonData = try createWorkoutJSON(from: workouts)
                    try jsonData.write(to: url)
                    completion(.success(url))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - CSV Creation
    
    private static func createCSV(from metrics: [HealthMetric]) throws -> String {
        var csv = "Date,Type,Value,Unit,Source\n"
        
        for metric in metrics {
            let dateString = metric.date?.ISO8601Format() ?? ""
            let type = metric.type ?? "Unknown"
            let value = String(metric.value)
            let unit = metric.unit ?? ""
            let source = metric.source ?? "Unknown"
            
            csv += "\(dateString),\(type),\(value),\(unit),\(source)\n"
        }
        
        return csv
    }
    
    private static func createWorkoutCSV(from workouts: [Workout]) throws -> String {
        var csv = "Start Date,End Date,Type,Duration (min),Distance (m),Calories,Source\n"
        
        for workout in workouts {
            let startDate = workout.startDate?.ISO8601Format() ?? ""
            let endDate = workout.endDate?.ISO8601Format() ?? ""
            let type = workout.type ?? "Unknown"
            let duration = String(format: "%.2f", workout.duration / 60)
            let distance = String(format: "%.2f", workout.totalDistance)
            let calories = String(format: "%.2f", workout.totalEnergyBurned)
            let source = workout.source ?? "Unknown"
            
            csv += "\(startDate),\(endDate),\(type),\(duration),\(distance),\(calories),\(source)\n"
        }
        
        return csv
    }
    
    // MARK: - JSON Creation
    
    private static func createJSON(from metrics: [HealthMetric]) throws -> Data {
        let exportData = metrics.map { metric in
            [
                "id": metric.id?.uuidString ?? "",
                "date": metric.date?.ISO8601Format() ?? "",
                "type": metric.type ?? "Unknown",
                "value": metric.value,
                "unit": metric.unit ?? "",
                "source": metric.source ?? "Unknown",
                "syncedAt": metric.syncedAt?.ISO8601Format() ?? ""
            ] as [String: Any]
        }
        
        let jsonObject: [String: Any] = [
            "exportDate": Date().ISO8601Format(),
            "metricsCount": metrics.count,
            "metrics": exportData
        ]
        
        return try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
    }
    
    private static func createWorkoutJSON(from workouts: [Workout]) throws -> Data {
        let exportData = workouts.map { workout in
            [
                "id": workout.id?.uuidString ?? "",
                "type": workout.type ?? "Unknown",
                "startDate": workout.startDate?.ISO8601Format() ?? "",
                "endDate": workout.endDate?.ISO8601Format() ?? "",
                "duration": workout.duration,
                "totalDistance": workout.totalDistance,
                "totalEnergyBurned": workout.totalEnergyBurned,
                "source": workout.source ?? "Unknown",
                "syncedAt": workout.syncedAt?.ISO8601Format() ?? ""
            ] as [String: Any]
        }
        
        let jsonObject: [String: Any] = [
            "exportDate": Date().ISO8601Format(),
            "workoutsCount": workouts.count,
            "workouts": exportData
        ]
        
        return try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
    }
}

// MARK: - Export View Integration

extension HealthBrowserViewModel {
    func exportData() {
        // Show export format picker
        let alert = NSAlert()
        alert.messageText = "Export Data"
        alert.informativeText = "Choose export format:"
        alert.addButton(withTitle: "CSV")
        alert.addButton(withTitle: "JSON")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        guard response != .alertThirdButtonReturn else { return }
        
        let format: ExportManager.ExportFormat = response == .alertFirstButtonReturn ? .csv : .json
        
        // Fetch current metrics based on selected category
        // This is a simplified version - you'll need to fetch actual data from CoreData
        guard let category = selectedCategory else {
            showError("Please select a category to export")
            return
        }
        
        // Export based on category type
        if category == .workouts {
            exportWorkouts(format: format)
        } else {
            exportMetrics(format: format)
        }
    }
    
    private func exportMetrics(format: ExportManager.ExportFormat) {
        // TODO: Fetch metrics from CoreData based on selected category and date range
        // For now, this is a placeholder
        let metrics: [HealthMetric] = [] // Fetch from CoreData
        
        ExportManager.exportMetrics(metrics, format: format) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    self.showSuccess("Exported to \(url.lastPathComponent)")
                case .failure(let error):
                    self.showError(error.localizedDescription)
                }
            }
        }
    }
    
    private func exportWorkouts(format: ExportManager.ExportFormat) {
        // TODO: Fetch workouts from CoreData based on date range
        let workouts: [Workout] = [] // Fetch from CoreData
        
        ExportManager.exportWorkouts(workouts, format: format) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    self.showSuccess("Exported to \(url.lastPathComponent)")
                case .failure(let error):
                    self.showError(error.localizedDescription)
                }
            }
        }
    }
    
    private func showSuccess(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Export Successful"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Export Failed"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}
