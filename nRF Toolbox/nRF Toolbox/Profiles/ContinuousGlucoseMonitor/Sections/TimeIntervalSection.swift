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


import Core 
import UIKit

class TimeIntervalSection: Section {
    private var timeSliderModel = StepperCellModel(min: 1, max: 10, step: 1, value: 1)

    let timeIntervalChanged: (Int) -> ()

    func dequeCell(for index: Int, from tableView: UIKit.UITableView) -> UIKit.UITableViewCell {
        let cell = tableView.dequeueCell(ofType: StepperTableViewCell.self)
        cell.update(with: timeSliderModel)
        cell.timeIntervalChanges = { [unowned self] ti in
            self.timeSliderModel.value = Double(ti)
            self.timeIntervalChanged(ti)
        }
        return cell
    }

    func reset() { }

    let numberOfItems: Int = 1
    let sectionTitle: String = "Time Interval"
    let id: Identifier<Section>
    let isHidden: Bool = false

    init(id: Identifier<Section>, timeIntervalChanged: @escaping (Int) -> () ) {
        self.id = id
        self.timeIntervalChanged = timeIntervalChanged
    }

    //TODO: Check correct size
    func cellHeight(for index: Int) -> CGFloat { 54.0 }
}
