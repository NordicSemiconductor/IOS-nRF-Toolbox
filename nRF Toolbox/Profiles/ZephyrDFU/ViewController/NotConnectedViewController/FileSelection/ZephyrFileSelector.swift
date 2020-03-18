//
//  ZephyrFileSelector.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 17/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class ZephyrFileSelector: FileSelectorViewController<Data> {
    weak var router: ZephyrDFURouterType?
    
    init(router: ZephyrDFURouterType? = nil, documentPicker: DocumentPicker<Data>) {
        self.router = router
        super.init(documentPicker: documentPicker)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func documentWasOpened(document: Data) {
        router?.goToUpdateScreen(data: document)
    }
}

