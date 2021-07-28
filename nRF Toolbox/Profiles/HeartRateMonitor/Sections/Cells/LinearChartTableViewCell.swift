/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



import UIKit
import Charts

extension DateFormatter: AxisValueFormatter {
    public func stringForValue(_ value: Double,
                        axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value)
        return string(from: date)
    }
}

class LinearChartTableViewCell: UITableViewCell {
    
    var maxVisibleXRange = 30.0

    let chartsView = LineChartView()
    
    var dateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "mm:ss"
            return dateFormatter
        }() {
        didSet {
            chartsView.xAxis.valueFormatter = dateFormatter
        }
    }

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
        chartsView.setVisibleXRangeMaximum(maxVisibleXRange)
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
        let xMax = max((first + maxVisibleXRange), last)
        
        chartsView.xAxis.axisMaximum = xMax
        chartsView.xAxis.axisMinimum = first
        
        let set = LineChartDataSet(entries: chartValues, label: "")
        set.drawCirclesEnabled = false
        set.drawValuesEnabled = false
        
        data.dataSets = [set]
        
        return data
    }

}
