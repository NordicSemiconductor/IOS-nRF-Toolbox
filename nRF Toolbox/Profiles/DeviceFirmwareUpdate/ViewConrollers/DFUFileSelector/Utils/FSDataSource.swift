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
import UIKit.UIImage

struct FSNodeRepresentation {
    var node: FSNode
    
    var level: Int
    var name: String
    var collapsed: Bool
    var size: Int
    var image: UIImage
    
    var modificationDate: Date?
    var sizeInfo: String
    var valid: Bool
}

struct FSDataSource {
    var items: [FSNodeRepresentation] = []
    var fileExtensionFilter: String?
    
    mutating func updateItems(_ dir: Directory) {
        items = items(dir, level: 0)
    }
    
    func items(_ dir: Directory, level: Int = 0) -> [FSNodeRepresentation] {
        dir.nodes.reduce([FSNodeRepresentation]()) { (result, node) in
            let valid: Bool
            if node is File, let ext = fileExtensionFilter, node.url.pathExtension != ext {
                valid = false
            } else {
                valid = true
            }
            
            var res = result
            let image = (node is Directory)
                ? ImageWrapper(icon: .folder, imageName: "folderEmpty").image
                : UIImage.icon(forFileURL: node.url, preferredSize: .smallest)
            
            let infoText: String
            if let dir = node as? Directory {
                infoText = "\(dir.nodes.count) items"
            } else {
                infoText = ByteCountFormatter().string(fromByteCount: Int64((node as! File).size))
            }
            
            res.append(FSNodeRepresentation(node: node, level: level, name: node.name, collapsed: false, size: 0, image: image!, modificationDate: node.resourceModificationDate, sizeInfo: infoText, valid: valid))
            if let dir = node as? Directory {
                res.append(contentsOf: self.items(dir, level: level + 1))
            }
            return res
        }
    }
}
