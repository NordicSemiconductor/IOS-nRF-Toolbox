//
//  Identifiable.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 12/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct Identifier<Value>: Equatable {
    let string: String
}

func ==<T>(lhs: Identifier<T>, rhs: Identifier<T>) -> Bool {
    return lhs.string == rhs.string
}

func ~=<T>(pattern: Identifier<T>, value: Identifier<T>) -> Bool {
    return pattern.string == value.string
}

extension Identifier: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        string = value
    }
}

extension Identifier: CustomStringConvertible {
    var description: String {
        return string
    }
}

extension Identifier: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.string)
    }
}
