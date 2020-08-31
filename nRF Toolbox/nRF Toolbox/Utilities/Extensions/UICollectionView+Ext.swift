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

extension UICollectionView {
    func dequeueCell<T: UICollectionViewCell>(ofType type: T.Type, for indexPath: IndexPath) -> T {
        let cellId = String(describing: type)
        guard let cell = dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? T else {
            SystemLog(category: .ui, type: .error).log(message: "Can not dequeue cell of type `\(cellId)` with cell ID '\(cellId)'")
            fatalError("Can not dequeue cell")
        }
        return cell
    }
    
    func registerCellNib<T>(type: T.Type) where T: UICollectionViewCell {
        let cellId = String(describing: type)
        let nib = UINib(nibName: cellId, bundle: .main)
        register(nib, forCellWithReuseIdentifier: cellId)
    }
    
    func registerCellClass<T>(type: T.Type) where T: UICollectionViewCell {
        let cellId = String(describing: type)
        self.register(T.self, forCellWithReuseIdentifier: cellId)
    }
    
    func registerViewNib<T>(type: T.Type, ofKind kind: String) where T: UICollectionReusableView {
        let viewId = String(describing: type)
        let nib = UINib(nibName: viewId, bundle: .main)
        register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: viewId)
    }
    
    func dequeueView<T: UICollectionReusableView>(type: T.Type, ofKind kind: String, for indexPath: IndexPath) -> T {
        let viewId = String(describing: type)
        let view = dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: viewId, for: indexPath) as! T
        return view
    }
}
