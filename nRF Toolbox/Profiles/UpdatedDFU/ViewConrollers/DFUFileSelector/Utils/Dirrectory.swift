//
//  Dirrectory.swift
//  DirectoryInspecto
//
//  Created by Nick Kibysh on 26/03/2020.
//  Copyright © 2020 Nick Kibysh. All rights reserved.
//

import Foundation

protocol FSNode {
    var url: URL { get }
    var name: String { get }
    var resourceModificationDate: Date? { get }
}

extension FSNode {
    var name: String {
        return url.lastPathComponent
    }
}

struct File: FSNode {
    
    let url: URL
    let size: Int
    var resourceModificationDate: Date?
}

struct Directory: FSNode {
    
    let url: URL
    
    var nodes: [FSNode]
    var resourceModificationDate: Date?
}


