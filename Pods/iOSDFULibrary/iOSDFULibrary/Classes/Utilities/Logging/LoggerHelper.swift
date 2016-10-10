/*
* Copyright (c) 2016, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
* documentation and/or other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this
* software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
* HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
* LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
* ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
* USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

class LoggerHelper {
    fileprivate var logger:LoggerDelegate?
    
    init(_ logger:LoggerDelegate?) {
        self.logger = logger
    }
    
    func d(_ message:String) {
        log(withLevel: .debug, andMessage: message)
    }
    
    func v(_ message:String) {
        log(withLevel: .verbose, andMessage: message)
    }
    
    func i(_ message:String) {
        log(withLevel: .info, andMessage: message)
    }
    
    func a(_ message:String) {
        log(withLevel: .application, andMessage: message)
    }
    
    func w(_ message:String) {
        log(withLevel: .warning, andMessage: message)
    }
    
    func e(_ message:String) {
        log(withLevel: .error, andMessage: message)
    }
    
    func w(_ error:Error) {
        log(withLevel: .warning, andMessage: "Error \((error as NSError).code): \(error.localizedDescription)")
    }
    
    func e(_ error:Error) {
        log(withLevel: .error, andMessage: "Error \((error as NSError).code): \(error.localizedDescription)")
    }
    
    fileprivate func log(withLevel aLevel: LogLevel, andMessage aMessage: String) {
        if self.logger != nil {
            logger!.logWith(aLevel, message: aMessage)
        }
    }
}
