//
//  ChartView.swift
//  HealthBrowserMac
//
//  Created on 2026-03-03
//

import SwiftUI
import Charts

struct MetricChartView: View {
    let metrics: [HealthMetric]
    let title: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            if metrics.isEmpty {
                EmptyChartView()
            } else {
                Chart(metrics, id: \.id) { metric in
                    LineMark(
                        x: .value("Date", metric.date ?? Date()),
                        y: .value("Value", metric.value)
                    )
                    .foregroundStyle(color.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", metric.date ?? Date()),
                        y: .value("Value", metric.value)
                    )
                    .foregroundStyle(color.opacity(0.2).gradient)
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 300)
                
                // Stats Summary
                HStack(spacing: 30) {
                    StatView(label: "Average", value: averageValue, unit: metrics.first?.unit ?? "")
                    StatView(label: "Min", value: minValue, unit: metrics.first?.unit ?? "")
                    StatView(label: "Max", value: maxValue, unit: metrics.first?.unit ?? "")
                    StatView(label: "Total", value: totalValue, unit: metrics.first?.unit ?? "")
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
        )
    }
    
    private var averageValue: Double {
        guard !metrics.isEmpty else { return 0 }
        return metrics.map { $0.value }.reduce(0, +) / Double(metrics.count)
    }
    
    private var minValue: Double {
        metrics.map { $0.value }.min() ?? 0
    }
    
    private var maxValue: Double {
        metrics.map { $0.value }.max() ?? 0
    }
    
    private var totalValue: Double {
        metrics.map { $0.value }.reduce(0, +)
    }
}

struct WorkoutChartView: View {
    let workouts: [Workout]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Duration by Type")
                .font(.title2)
                .fontWeight(.semibold)
            
            if workouts.isEmpty {
                EmptyChartView()
            } else {
                Chart(workoutsByType, id: \.type) { item in
                    BarMark(
                        x: .value("Type", item.type),
                        y: .value("Duration", item.totalDuration / 60)
                    )
                    .foregroundStyle(by: .value("Type", item.type))
                    .annotation(position: .top) {
                        Text("\(Int(item.totalDuration / 60))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartYAxisLabel("Minutes")
                .frame(height: 300)
                
                // Workout Stats
                HStack(spacing: 30) {
                    StatView(label: "Total Workouts", value: Double(workouts.count), unit: "")
                    StatView(label: "Total Time", value: totalDuration / 60, unit: "min")
                    StatView(label: "Avg Duration", value: averageDuration / 60, unit: "min")
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
        )
    }
    
    private var workoutsByType: [(type: String, totalDuration: Double)] {
        let grouped = Dictionary(grouping: workouts) { $0.type ?? "Unknown" }
        return grouped.map { (type: $0.key, totalDuration: $0.value.map { $0.duration }.reduce(0, +)) }
            .sorted { $0.totalDuration > $1.totalDuration }
    }
    
    private var totalDuration: Double {
        workouts.map { $0.duration }.reduce(0, +)
    }
    
    private var averageDuration: Double {
        guard !workouts.isEmpty else { return 0 }
        return totalDuration / Double(workouts.count)
    }
}

struct StatView: View {
    let label: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(value, specifier: "%.1f") \(unit)")
                .font(.title3)
                .fontWeight(.semibold)
        }
    }
}

struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Data Available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Sync data from your iPhone to see charts")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let request = HealthMetric.fetchRequest()
    let metrics = try? context.fetch(request)
    
    return MetricChartView(
        metrics: metrics ?? [],
        title: "Steps Over Time",
        color: .blue
    )
    .padding()
    .frame(width: 600)
}
