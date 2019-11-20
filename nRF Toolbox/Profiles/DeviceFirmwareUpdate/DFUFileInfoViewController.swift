//
// Created by Nick Kibysh on 18/11/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

class DFUFileInfoViewController: UITableViewController {
    let fileURL: URL

    init(url: URL) {
        self.fileURL = url
        super.init(style: .grouped)
        
        let firmware = DFUFirmware(urlToZipFile: url)
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension DFUFileInfoViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
}
