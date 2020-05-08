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

extension Identifier where Value == ControlSection.Item {
    static let resume = Identifier<Value>(string: "resume")
    static let pause = Identifier<Value>(string: "pause")
    static let showLog = Identifier<Value>(string: "showLog")
    static let retry = Identifier<Value>(string: "retry")
    static let done = Identifier<Value>(string: "done")
    static let stop = Identifier<Value>(string: "stop")
}

class ControlSection: Section {
    
    struct Item {
        let id: Identifier<Item>
        let title: String
        
        static let pause = Item(id: .pause, title: "Pause")
        static let resume = Item(id: .resume, title: "Resume")
        static let showLog = Item(id: .showLog, title: "Show Log")
        static let retry = Item(id: .retry, title: "Retry")
        static let done = Item(id: .done, title: "Done")
        static let stop = Item(id: .stop, title: "Stop")
    }
    
    var callback: ((Item) -> ())!
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
        let item = items[index]
        
        if item.id == .stop {
            cell.textLabel?.textColor = .nordicRed
        } else {
            cell.textLabel?.textColor = .systemBlue
        }
        
        cell.textLabel?.text = item.title
        return cell
    }
    
    func reset() { }
    func didSelectItem(at index: Int) {
        let item = items[index]
        callback(item)
    }
    
    var numberOfItems: Int {
        items.count
    }
    
    var sectionTitle: String = ""
    var id: Identifier<Section> = "ControlSection"
    var isHidden: Bool { items.isEmpty }
    var items: [Item] = []
    
    
}
