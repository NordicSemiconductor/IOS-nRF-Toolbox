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

private extension Identifier where Value == DetailsTableViewCellModel {
    static let numberOfSteps: Identifier<DetailsTableViewCellModel> = "NumberOfSteps"
}

class RunningSpeedSection: DetailsTableViewSection<RunningCharacteristic> {
    
    private var numberOfSteps: Int = 0
    private var startDate: Date = Date()
    private var timer: Timer?
    
    override var sectionTitle: String { "Speed and Cadence" }
    
    override func reset() {
        timer?.invalidate()
        numberOfSteps = 0
        super.reset()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    override func update(with characteristic: RunningCharacteristic) {
        let runningData = characteristic //RunningCharacteristic(data: data)
        let cadence = runningData.instantaneousCadence
        var items: [DefaultDetailsTableViewCellModel] = [
            DefaultDetailsTableViewCellModel(title: "Pace", value: PaceMeasurementFormatter().paceString(from: runningData.instantaneousSpeed)),
            DefaultDetailsTableViewCellModel(title: "Cadence", value: "\(cadence) RPM")
        ]
        
        if let distance = runningData.totalDistance, let strideLength = runningData.instantaneousStrideLength {
            items += [
                DefaultDetailsTableViewCellModel(title: "Total Distance", value: MeasurementFormatter().string(from: distance)),
                DefaultDetailsTableViewCellModel(title: "Stride Length", value: MeasurementFormatter().string(from: strideLength))
            ]
        }
        
        items.append(DefaultDetailsTableViewCellModel(title: "Number of Steps", value: "\(numberOfSteps)", identifier: .numberOfSteps))
        
        self.items = items
        super.update(with: characteristic)
        
        timer?.invalidate()
        if cadence > 0 {
            timer = Timer.scheduledTimer(withTimeInterval: 60.0 / Double(cadence), repeats: true) { [weak self] (timer) in
                guard let `self` = self else { return }
                self.numberOfSteps += 1
                
                self.items
                    .firstIndex(where: { $0.identifier == .numberOfSteps })
                    .map {
                        var item = self.items[$0] as! DefaultDetailsTableViewCellModel
                        item.details = "\(self.numberOfSteps)"
                        self.items[$0] = item
                    }
                
                self.itemUpdated?(self.id, .numberOfSteps)
            }
        }
    }
    
    
    
}
