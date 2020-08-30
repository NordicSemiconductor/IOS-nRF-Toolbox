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
import HomeKit
import Core 

struct AccessoriesSection: Section {
    var items: [HMAccessory] = []
    var home: HMHome?
    
    init(sectionTitle: String, footer: String?, id: Identifier<Section>) {
        self.sectionTitle = sectionTitle
        self.id = id
        self.sectionFooter = footer
    }
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let accessory = items[index]
        
        let homeName = home?.name
        let roomName = accessory.room?.name
        let detailsTitle = [roomName, homeName].compactMap { $0 }.joined(separator: " in ")
        
        let cell = tableView.dequeueCell(ofType: NordicBottomDetailsTableViewCell.self)
        cell.textLabel?.text = accessory.name
        cell.detailTextLabel?.text = detailsTitle
        
        return cell
    }
    
    mutating func reset() { }
    
    var numberOfItems: Int { items.count }
    
    var sectionTitle: String
    var sectionFooter: String?
    
    var id: Identifier<Section>
    
    var isHidden: Bool { items.isEmpty }
    
}
