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



import Foundation

class BloodPressureSection: DetailsTableViewSection<BloodPressureCharacteristic> {
    
    override init(id: Identifier<Section>, sectionUpdated: ((Identifier<Section>) -> ())? = nil, itemUpdated: ((Identifier<Section>, Identifier<DetailsTableViewCellModel>) -> ())? = nil) {
        super.init(id: id, sectionUpdated: sectionUpdated, itemUpdated: itemUpdated)
    }
    
    override var sectionTitle: String { "Blood Pressure" }
    
    override func reset() {
        items = [
            DefaultDetailsTableViewCellModel(title: "Systolic", value: "-"),
            DefaultDetailsTableViewCellModel(title: "Diastolic", value: "-"),
            DefaultDetailsTableViewCellModel(title: "Mean AP", value: "-")
        ]
    }
    
    override func update(with characteristic: BloodPressureCharacteristic) {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        
        let systolicItem = DefaultDetailsTableViewCellModel(title: "Systolic", value: formatter.string(from: characteristic.systolicPressure))
        let diastolicItem = DefaultDetailsTableViewCellModel(title: "Diastolic", value: formatter.string(from: characteristic.diastolicPressure))
        let maItem = DefaultDetailsTableViewCellModel(title: "Mean AP", value: formatter.string(from: characteristic.meanArterialPressure))
        
        items = [systolicItem, diastolicItem, maItem]
    }
}
