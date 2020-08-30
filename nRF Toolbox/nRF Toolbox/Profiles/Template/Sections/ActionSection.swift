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
import Core 

struct ActionSectionItem {
    enum Style {
        case `default`, destructive
    }
    
    let title: String
    let style: Style
    let action: () -> ()
    
    init(title: String, style: Style = .default, action: @escaping () -> ()) {
        self.title = title
        self.style = style
        self.action = action
    }
}

class ActionSection: Section {
    var isHidden: Bool = false 
    
    func dequeCell(for index: Int, from tableView: UITableView) -> UITableViewCell {
        let item = items[index]
        return dequeueCell(item: item, at: index, from: tableView)
    }

    func dequeueCell(item: ActionSectionItem, at index: Int, from tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell")

        cell?.textLabel?.font = UIFont.gtEestiDisplay(.regular, size: 17.0)
        cell?.textLabel?.text = item.title
        cell?.textLabel?.textColor = {
            switch item.style {
            case .default: return UIColor.Button.action
            case .destructive: return UIColor.Button.destructive
            }
        }()
        return cell!
    }
    
    func reset() {
//        items = []
    }
    
    var numberOfItems: Int { items.count }
    
    var sectionTitle: String
    let id: Identifier<Section>
    var items: [ActionSectionItem] = []
    
    init(id: Identifier<Section>, sectionTitle: String, items: [ActionSectionItem]) {
        self.id = id
        self.sectionTitle = sectionTitle
        self.items = items
    }
    
}
