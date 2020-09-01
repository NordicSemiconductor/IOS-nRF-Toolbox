//
//  Configuration.swift
//  Core
//
//  Created by Nick Kibysh on 01/09/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

public enum Configuration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    public static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey:key) else {
            throw Error.missingKey
        }

        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }
}
