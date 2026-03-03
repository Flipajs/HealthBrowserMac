//
//  ContentView.swift
//  HealthBrowserMac
//
//  Created on 2026-03-03
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = HealthBrowserViewModel()
    
    var body: some View {
        NavigationSplitView {
            // Sidebar: Metric categories
            SidebarView(selectedCategory: $viewModel.selectedCategory)
        } content: {
            // List: Metrics for selected category
            MetricListView()
                .environmentObject(viewModel)
        } detail: {
            // Detail: Chart and detailed view
            DetailView()
                .environmentObject(viewModel)
        }
        .navigationTitle("Health Browser")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                DateRangePicker(dateRange: $viewModel.dateRange)
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: viewModel.exportData) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}

struct SidebarView: View {
    @Binding var selectedCategory: MetricCategory?
    
    var body: some View {
        List(MetricCategory.allCases, selection: $selectedCategory) { category in
            Label(category.title, systemImage: category.icon)
                .tag(category)
        }
        .navigationTitle("Categories")
    }
}

struct MetricListView: View {
    @EnvironmentObject var viewModel: HealthBrowserViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HealthMetric.date, ascending: false)],
        animation: .default
    )
    private var metrics: FetchedResults<HealthMetric>
    
    var body: some View {
        List(filteredMetrics) { metric in
            MetricRowView(metric: metric)
                .onTapGesture {
                    viewModel.selectedMetric = metric
                }
        }
        .navigationTitle(viewModel.selectedCategory?.title ?? "Metrics")
    }
    
    private var filteredMetrics: [HealthMetric] {
        metrics.filter { metric in
            guard let category = viewModel.selectedCategory else { return true }
            return metric.type == category.rawValue
        }
    }
}

struct MetricRowView: View {
    let metric: HealthMetric
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(metric.date ?? Date(), style: .date)
                    .font(.headline)
                Text(metric.type ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(metric.value, specifier: "%.0f") \(metric.unit ?? "")")
                .font(.title3)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

struct DetailView: View {
    @EnvironmentObject var viewModel: HealthBrowserViewModel
    
    var body: some View {
        VStack {
            if let metric = viewModel.selectedMetric {
                MetricDetailView(metric: metric)
            } else {
                EmptyStateView()
            }
        }
    }
}

struct MetricDetailView: View {
    let metric: HealthMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(metric.type ?? "Unknown")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(metric.date ?? Date(), style: .date)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(metric.value, specifier: "%.0f")")
                        .font(.system(size: 48, weight: .bold))
                    Text(metric.unit ?? "")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
            
            // Chart placeholder
            ChartPlaceholderView()
            
            // Details
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(label: "Source", value: metric.source ?? "Unknown")
                DetailRow(label: "Synced", value: metric.syncedAt?.formatted() ?? "Unknown")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
            )
            
            Spacer()
        }
        .padding()
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct ChartPlaceholderView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.secondary.opacity(0.1))
            .frame(height: 300)
            .overlay(
                Text("Chart Coming Soon")
                    .font(.title2)
                    .foregroundColor(.secondary)
            )
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Metric Selected")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Select a metric from the list to view details")
                .foregroundColor(.secondary)
        }
    }
}

struct DateRangePicker: View {
    @Binding var dateRange: DateRange
    
    var body: some View {
        Picker("Date Range", selection: $dateRange) {
            ForEach(DateRange.allCases) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(.menu)
    }
}

// MARK: - View Models

class HealthBrowserViewModel: ObservableObject {
    @Published var selectedCategory: MetricCategory?
    @Published var selectedMetric: HealthMetric?
    @Published var dateRange: DateRange = .week
    
    func exportData() {
        // TODO: Implement export functionality
        print("Export data")
    }
}

// MARK: - Enums

enum MetricCategory: String, CaseIterable, Identifiable {
    case steps
    case heartRate
    case activeEnergy
    case workouts
    case sleep
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .steps: return "Steps"
        case .heartRate: return "Heart Rate"
        case .activeEnergy: return "Active Energy"
        case .workouts: return "Workouts"
        case .sleep: return "Sleep"
        }
    }
    
    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .heartRate: return "heart.fill"
        case .activeEnergy: return "flame.fill"
        case .workouts: return "dumbbell.fill"
        case .sleep: return "bed.double.fill"
        }
    }
}

enum DateRange: String, CaseIterable, Identifiable {
    case today
    case week
    case month
    case year
    case all
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .today: return "Today"
        case .week: return "Last 7 Days"
        case .month: return "Last 30 Days"
        case .year: return "Last Year"
        case .all: return "All Time"
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
