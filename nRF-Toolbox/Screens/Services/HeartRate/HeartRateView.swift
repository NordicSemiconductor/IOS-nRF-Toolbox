//
//  HeartRateView.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 25/10/2023.
//  Created by Dinesh Harjani on 5/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import Charts
import iOS_Common_Libraries

// MARK: - HeartRateChart

struct HeartRateChart: View {
    
    // MARK: Environment
    
    @Environment(HeartRateViewModel.self) private var viewModel: HeartRateViewModel

    // MARK: view
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Heart Rate")
                    .font(.title2.bold())
                
                Spacer()
                
                if #available(iOS 18.0, *) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.nordicRed)
                        .symbolEffect(.bounce.up, options: .repeat(.periodic(delay: 0.1)))
                } else {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.nordicRed)
                }
                
                Text("\(viewModel.data.last?.measurement.heartRateValue ?? 0) BPM")
                    .foregroundStyle(.secondary)
            }
        
            @Bindable var bindableVM = viewModel
            Chart {
                ForEach(viewModel.data, id: \.date) { value in
                    LineMark(
                        x: .value("Date", value.date),
                        y: .value("Heart Rate", value.measurement.heartRateValue)
                    )
                    .foregroundStyle(Color.nordicRed)
                    
                    PointMark(
                        x: .value("Date", value.date),
                        y: .value("Heart Rate", value.measurement.heartRateValue)
                    )
                    .foregroundStyle(Color.nordicRed)
                }
                .interpolationMethod(.catmullRom)
            }
            .chartXScale(domain: [viewModel.minDate, viewModel.maxDate], range: .plotDimension(padding: 8))
            .chartXAxis(.hidden)
            .chartYScale(domain: [viewModel.lowest, viewModel.highest], range: .plotDimension(padding: 8))
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: viewModel.visibleDomain)
            .chartScrollPosition(x: $bindableVM.scrollPosition)
            
            if let lastMeasurement = viewModel.data.last {
                Label(lastMeasurement.measurement.sensorContact.description, systemImage: "hand.rays.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer().frame(height: 6)
                
                let caloriesUsage = lastMeasurement.measurement.energyExpended ?? 0
                Label("Burnt calories: \(caloriesUsage)", systemImage: "bolt.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer().frame(height: 4)
                
                Label("RR Intervals Received: \(lastMeasurement.measurement.intervals?.count ?? 0)", systemImage: "arrow.left.and.right.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer().frame(height: 4)
            }
            
            if let sensorLocation = viewModel.location {
                Label("Location: \(sensorLocation.description)", systemImage: "figure.dance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            RefreshCaloriesCounterView()
        }
        .padding(.vertical, 4)
    }
}

struct RefreshCaloriesCounterView: View {
    
    @Environment(HeartRateViewModel.self) private var viewModel: HeartRateViewModel
    
    @State var showAlert = false
    
    var body: some View {
        if (viewModel.caloriesResetState != .unavailable) {
            HStack {
                Spacer() // Pushes the button to the right
                
                ZStack {
                    ProgressView()
                        .fixedCircularProgressView()
                        .centered()
                        .listRowSeparator(.hidden)
                        .hidden(viewModel.caloriesResetState != .inProgress)
                    
                    Button("Reset calories") {
                        viewModel.resetMeasurement()
                    }
                    .tint(.nordicBlue)
                    .padding(8)
                    .hidden(viewModel.caloriesResetState != .available)
                }.fixedSize()
            }.alert("Error occured",isPresented: $showAlert, actions: {
                Button("OK") {
                    viewModel.clearControlPointError()
                }
            })
            
        }
    }
}

extension View {
    
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }
}

// MARK: - HeartRateView

struct HeartRateView: View {
    
    // MARK: Environment
    
    @Environment(HeartRateViewModel.self) private var viewModel: HeartRateViewModel
    
    // MARK: view
    
    var body: some View {
        if viewModel.data.isEmpty {
            NoContentView(title: "No Heart Rate Data", systemImage: "waveform.path.ecg.rectangle")
        } else {
            HeartRateChart()
        }
    }
}
