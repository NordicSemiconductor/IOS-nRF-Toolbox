//
//  XMLFileDocument.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 04/11/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct XMLFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.xml] }
    
    var content: String
    
    init(content: String = "") {
        self.content = content
    }
    
    init(configuration: ReadConfiguration) throws {
        if let string = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) {
            self.content = string
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = content.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}
