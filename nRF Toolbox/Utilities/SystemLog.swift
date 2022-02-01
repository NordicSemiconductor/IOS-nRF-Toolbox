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
import os.log

protocol Logger {
    func log(level aLevel: LogType, message aMessage: String)
}

struct LogType: Equatable, RawRepresentable {
    typealias RawValue = String
    
    let rawValue: String
    
    init?(rawValue: String) {
        self.rawValue = rawValue
    }
    
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
    static let verbose = LogType(rawValue: "verboseLogLevel")!
    static let application = LogType(rawValue: "application")!
    static let warning = LogType(rawValue: "warning")!
}

extension LogType: CaseIterable {
    static var allCases: [LogType] {
        return [
            .debug, .verbose, .info, .application, .warning, .error
        ]
    }
}

extension LogType {
    var name: String {
        switch self {
        case .application: return "Application"
        case .debug: return "Debug"
        case .default: return "Default"
        case .error: return "Error"
        case .fault: return "Fault"
        case .info: return "Info"
        case .verbose: return "Verbose"
        case .warning: return "Warning"
        default: return "Unknown"
        }
    }
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
    static let update = LogCategory(rawValue: "update")!
}

struct SystemLog {
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
