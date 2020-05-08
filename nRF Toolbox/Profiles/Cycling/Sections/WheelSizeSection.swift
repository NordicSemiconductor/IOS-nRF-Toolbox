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

class WheelSizeSection: Section {

    private let wheelSizeKey = "wheel_size"
    private (set) var wheelSize: Measurement<UnitLength>

    init() {
        if let data = UserDefaults.standard.value(forKey: wheelSizeKey) as? Data,
           let size = try? PropertyListDecoder().decode(Measurement<UnitLength>.self, from: data) {
            self.wheelSize = size
        } else {
            self.wheelSize = Measurement<UnitLength>(value: 600, unit: .millimeters)
        }
    }

    var wheelSizeChangedAction: ((Measurement<UnitLength>) -> ())?

    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: SliderTableViewCell.self)

        let units: UnitLength = .inches

        cell.slider.minimumValue = 20
        cell.slider.maximumValue = 29

        let unitFormatter = MeasurementFormatter()
        unitFormatter.numberFormatter = .zeroDecimal
        unitFormatter.unitOptions = .providedUnit

        cell.action = { value in
            self.wheelSize = Measurement<UnitLength>(value: value, unit: units)
            let data = try? PropertyListEncoder().encode(self.wheelSize)
            UserDefaults.standard.set(data, forKey: self.wheelSizeKey)
        }

        cell.slider.value = Float(wheelSize.converted(to: units).value)

        let inchStr = unitFormatter.string(from: wheelSize.converted(to: .inches))
        let mmStr = unitFormatter.string(from: wheelSize.converted(to: .millimeters))
        cell.title.text = "\(inchStr) / \(mmStr)"

        return cell
    }

    func reset() {  }

    private(set) var numberOfItems: Int = 1
    private(set) var sectionTitle: String = "Wheel Size"
    private(set) var id: Identifier<Section> = "WheelSizeSection"
    private(set) var isHidden: Bool = false

    func cellHeight(for index: Int) -> CGFloat { 80.0 }

    func registerCells(_ tableView: UITableView) {
        tableView.registerCellNib(cell: SliderTableViewCell.self)
    }
}
