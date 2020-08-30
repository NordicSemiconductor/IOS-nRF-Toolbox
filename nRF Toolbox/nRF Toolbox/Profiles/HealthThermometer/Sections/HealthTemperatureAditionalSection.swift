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
import Foundation

class HealthTemperatureAditionalSection: DetailsTableViewSection<HealthTermometerCharacteristic> {
    
    override var isHidden: Bool { false }
    
    override init(id: Identifier<Section>, sectionUpdated: ((Identifier<Section>) -> ())? = nil, itemUpdated: ((Identifier<Section>, Identifier<DetailsTableViewCellModel>) -> ())? = nil) {
        super.init(id: id, sectionUpdated: sectionUpdated, itemUpdated: itemUpdated)
    }
    
    override func update(with characteristic: HealthTermometerCharacteristic) {
        
        var items: [DetailsTableViewCellModel] = []
        
        characteristic.timeStamp.map {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let dateString = dateFormatter.string(from: $0)
            items.append(DefaultDetailsTableViewCellModel(title: "Date / Time", value: dateString))
        }
        
        characteristic.type.map {
            items.append(DefaultDetailsTableViewCellModel(title: "Location", value: $0.description))
        }
        
        self.items = items
        
        super.update(with: characteristic)
    }
}
