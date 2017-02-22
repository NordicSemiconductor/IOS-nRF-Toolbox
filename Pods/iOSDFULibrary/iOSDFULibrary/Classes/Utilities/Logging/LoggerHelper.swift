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
    private var logger: LoggerDelegate?
    
    init(_ logger: LoggerDelegate?) {
        self.logger = logger
    }
    
    func d(_ message: String) {
        logger?.logWith(.debug, message: message)
    }
    
    func v(_ message: String) {
        logger?.logWith(.verbose, message: message)
    }
    
    func i(_ message: String) {
        logger?.logWith(.info, message: message)
    }
    
    func a(_ message: String) {
        logger?.logWith(.application, message: message)
    }
    
    func w(_ message: String) {
        logger?.logWith(.warning, message: message)
    }
    
    func e(_ message: String) {
        logger?.logWith(.error, message: message)
    }
    
    func w(_ error: Error) {
        logger?.logWith(.warning, message: "Error \((error as NSError).code): \(error.localizedDescription)")
    }
    
    func e(_ error: Error) {
        logger?.logWith(.error, message: "Error \((error as NSError).code): \(error.localizedDescription)")
    }
}
