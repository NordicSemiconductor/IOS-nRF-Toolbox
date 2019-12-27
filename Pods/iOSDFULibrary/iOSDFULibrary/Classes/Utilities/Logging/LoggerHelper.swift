/*
* Copyright (c) 2019, Nordic Semiconductor
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

class LoggerHelper {
    private weak var logger: LoggerDelegate?
    private var queue: DispatchQueue
    
    init(_ logger: LoggerDelegate?, _ queue: DispatchQueue) {
        self.logger = logger
        self.queue = queue
    }
    
    func d(_ message: String) {
        log(with: .debug, message: message)
    }
    
    func v(_ message: String) {
        log(with: .verbose, message: message)
    }
    
    func i(_ message: String) {
        log(with: .info, message: message)
    }
    
    func a(_ message: String) {
        log(with: .application, message: message)
    }
    
    func w(_ message: String) {
        log(with: .warning, message: message)
    }
    
    func e(_ message: String) {
        log(with: .error, message: message)
    }
    
    func w(_ error: Error) {
        log(with: .warning, message:
            "Error \((error as NSError).code): \(error.localizedDescription)")
    }
    
    func e(_ error: Error) {
        log(with: .error, message:
            "Error \((error as NSError).code): \(error.localizedDescription)")
    }

    private func log(with level: LogLevel, message: String) {
        if let logger = logger {
            queue.async {
                logger.logWith(level, message: message)
            }
        }
    }
}
