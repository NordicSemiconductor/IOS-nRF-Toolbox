//
//  XMLDocument.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 28/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import AEXML

class XMLDocument: UIDocument {
    enum Error: Swift.Error {
        case unableToEncodeXML
    }
    
    var doc: AEXMLDocument!
    
    init(name: String) {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("\(name).xml")
        super.init(fileURL: url)
    }
    
    override func contents(forType typeName: String) throws -> Any {
        guard let data = doc.xml.data(using: .utf8) else {
            throw Error.unableToEncodeXML
        }
        
        return data as Any
    }
}
