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

        let leftAxis = chartsView.leftAxis
        leftAxis.labelFont = .gtEestiDisplay(.light, size: 10)

        let xAxis = chartsView.xAxis
        xAxis.labelFont = .gtEestiDisplay(.light, size: 10)
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .none
        xAxis.valueFormatter = dateFormatter

        if #available(iOS 13, *) {
            leftAxis.axisLineColor = .label
            leftAxis.labelTextColor = .label

            xAxis.labelTextColor = .label
        }

        setupBorderAnchors()
    }

    private func setupBorderAnchors() {
        chartsView.translatesAutoresizingMaskIntoConstraints = false
        chartsView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        chartsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        chartsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        chartsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with data: [(x: TimeInterval, y: Double)]) {
        let dataSet = configureChartData(data)
        chartsView.data = dataSet
    }
    
    private func configureChartData(_ value: [(x: TimeInterval, y: Double)]) -> LineChartData? {
        guard value.count > 0 else { return nil }
        let chartValues = value.map { ChartDataEntry(x: $0.x, y: $0.y) }
        let set = LineChartDataSet(entries: chartValues, label: nil)
        return LineChartData(dataSet: set)
    }

}
