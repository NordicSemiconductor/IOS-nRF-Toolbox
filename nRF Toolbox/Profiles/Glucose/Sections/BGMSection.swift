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

class BGMSection: Section {
    var isHidden: Bool { numberOfItems == 0 }
    
    let id: Identifier<Section> = .bgmReadings
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: BGMTableViewCell.self)
        let reading = items[index]
        cell.update(with: reading)
        return cell
    }
    
    func reset() {
        items = []
    }
    
    var numberOfItems: Int {
        return items.count
    }
    
    var sectionTitle: String = "Readings"
    
    private (set) var items: [GlucoseReading] = []
    
    func clearReadings() {
        items.removeAll()
    }
    
    func update(reading: GlucoseReading) {
        guard let index = items.firstIndex(where: { $0 == reading }) else {
            items.append(reading)
            return
        }
        items[index] = reading
    }
    
    func update(context: GlucoseReadingContext) {
        guard let index = items.firstIndex(where: { $0.sequenceNumber == context.sequenceNumber }) else {
            SystemLog(category: .ble, type: .error).log(message: "Glucose measurement with sequence number: \(context.sequenceNumber) not found")
            return
        }
        
        items[index].context = context
    }

    func cellHeight(for index: Int) -> CGFloat { 75 }
}
