//
//  LinearChartTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 08/10/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import Charts

extension DateFormatter: IAxisValueFormatter {
    public func stringForValue(_ value: Double,
                        axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value)
        return string(from: date)
    }
}

class LinearChartTableViewCell: UITableViewCell {
    
    static let maxVisibleXRange = 30.0

    let chartsView = LineChartView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(chartsView)
        
        chartsView.legend.form = .empty
        chartsView.noDataText = "Retrieving data..."
        chartsView.noDataFont = .gtEestiDisplay(.thin, size: 32)
        chartsView.noDataTextAlignment = .center
        if #available(iOS 13, *) {
            chartsView.noDataTextColor = .systemGray2
        }
        
        chartsView.setScaleEnabled(false)
        chartsView.rightAxis.drawLabelsEnabled = false

        let leftAxis = chartsView.leftAxis
        leftAxis.labelFont = .gtEestiDisplay(.light, size: 10)

        let xAxis = chartsView.xAxis
        xAxis.labelFont = .gtEestiDisplay(.light, size: 10)
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .none
        xAxis.valueFormatter = dateFormatter
        
        chartsView.dragEnabled = true
        chartsView.dragDecelerationFrictionCoef = 0.35

        if #available(iOS 13, *) {
            leftAxis.axisLineColor = .label
            leftAxis.labelTextColor = .label
            xAxis.labelTextColor = .label
        }

        setupBorderAnchors()
    }

    private func setupBorderAnchors() {
        chartsView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            chartsView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            chartsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 16),
            chartsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            chartsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with data: [(x: TimeInterval, y: Double)]) {
        let dataSet = configureChartData(data)
        chartsView.data = dataSet
        chartsView.setVisibleXRangeMaximum(Self.maxVisibleXRange)
        guard let last = data.last?.x else { return }
        
        if chartsView.highestVisibleX.rounded(.up) >= chartsView.xAxis.axisMaximum - 2 {
            chartsView.moveViewToX(last)
        }
    }
    
    private func configureChartData(_ value: [(x: TimeInterval, y: Double)]) -> LineChartData? {
        guard value.count > 0 else { return nil }
        guard let first = value.first?.x else { return nil }

        let data = chartsView.data as? LineChartData ?? LineChartData()
        let chartValues = value.map { ChartDataEntry(x: $0.x, y: $0.y) }
        
        let last = value.last?.x ?? Double.leastNormalMagnitude
        let xMax = max((first + Self.maxVisibleXRange), last)
        
        chartsView.xAxis.axisMaximum = xMax
        chartsView.xAxis.axisMinimum = first
        
        let set = LineChartDataSet(entries: chartValues, label: nil)
        set.drawCirclesEnabled = false
        set.drawValuesEnabled = false
        
        data.dataSets = [set]
        
        return data
    }

}
