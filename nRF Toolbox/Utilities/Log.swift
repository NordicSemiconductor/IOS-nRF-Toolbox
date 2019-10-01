//
//  Log.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 16/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation
import os.log

struct LogType: Equatable, RawRepresentable {
    typealias RawValue = String
    
    let rawValue: String
    
    init?(rawValue: String) {
        self.rawValue = rawValue
    }
    
    @available(iOS 10.0, *)
    func osLogType() -> OSLogType {
        switch self {
        case .default: return .default
        case .info: return .info
        case .error: return .error
        case .fault: return .fault
        default: return .default
        }
    }
}

extension LogType {
    static let `default` = LogType(rawValue: "default")!
    static let info = LogType(rawValue: "info")!
    static let debug = LogType(rawValue: "debug")!
    static let error = LogType(rawValue: "error")!
    static let fault = LogType(rawValue: "fault")!
}

struct LogCategory: Equatable, RawRepresentable {
    typealias RawValue = String
    
    let rawValue: String
    
    init?(rawValue: String) {
        self.rawValue = rawValue
    }
    
    @available(iOS 10.0, *)
    func osLog() -> OSLog {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: rawValue)
    }
}

extension LogCategory {
    static let ui = LogCategory(rawValue: "ui")!
    static let ble = LogCategory(rawValue: "ble")!
    static let util = LogCategory(rawValue: "util")!
    static let app = LogCategory(rawValue: "application")!
}

struct Log {
    let category: LogCategory
    let type: LogType
    
    init(category: LogCategory, type: LogType) {
        self.category = category
        self.type = type
    }
    
    func log(message: String) {
        if #available(iOS 10.0, *) {
            os_log("%@", log: category.osLog(), type: type.osLogType(), message)
        } else {
            NSLog("%@", message)
        }
    }
    
    func fault(_ errorMessage: String) -> Never {
        if #available(iOS 10.0, *) {
            os_log("%@", log: category.osLog(), type: type.osLogType(), errorMessage)
        } else {
            NSLog("%@", errorMessage)
        }
        fatalError(errorMessage)
    }
}
