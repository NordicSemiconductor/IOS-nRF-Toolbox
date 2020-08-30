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

extension Identifier where Value == Section {
    static let bgMActionSection: Identifier<Section> = "BGMActionSection"
}

class BGMActionSection: Section {
    
    let numberOfItems: Int = 4
    let sectionTitle: String = "Actions"
    let id: Identifier<Section> = .bgMActionSection
    let isHidden: Bool = false
    
    func cellHeight(for index: Int) -> CGFloat {
        index == 0 ? 64 : 44
    }
    
    func registerRequiredCells(for tableView: UITableView) {
        tableView.registerCellClass(cell: NordicActionTableViewCell.self)
        tableView.registerCellNib(cell: BGMDisplayItemTableViewCell.self)
    }
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        if index == 0 {
            return dequeueDisplayCell(tableView)
        }
        
        let cell = tableView.dequeueCell(ofType: NordicActionTableViewCell.self)
        
        switch index {
        case 1:
            cell.style = .default
            cell.textLabel?.text = "Refresh"
        case 2:
            cell.style = .default
            cell.textLabel?.text = "Clear"
        case 3:
            cell.style = .destructive
            cell.textLabel?.text = "Delete All"
        default:
            break
        }
        
        return cell
    }
    
    func didSelectRaw(at index: Int) {
        switch index {
        case 1: refreshAction(displayItemActionId)
        case 2: clearAction()
        case 3: deleteAllAction()
        default: break
        }
    }
    
    func reset() { }
    
    private var displayItemActionId: Identifier<GlucoseMonitorViewController> = .all
    var refreshAction: ((Identifier<GlucoseMonitorViewController>) -> ())!
    var clearAction: (() -> ())!
    var deleteAllAction: (() -> ())!
    
    private func dequeueDisplayCell(_ tableView: UITableView) -> BGMDisplayItemTableViewCell {
        let cell = tableView.dequeueCell(ofType: BGMDisplayItemTableViewCell.self)
        cell.callback = { index in
            let id: Identifier<GlucoseMonitorViewController> = {
                switch index {
                case 0: return .all
                case 1: return .first
                case 2: return .last
                default: return ""
                }
            }()
            
            self.displayItemActionId = id
            self.refreshAction(id)
        }
        return cell
    }
    
}
