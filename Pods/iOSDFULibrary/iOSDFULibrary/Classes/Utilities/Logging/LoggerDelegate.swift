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

/**
Log level. Logger application may filter log entries based on their level. Levels allow to ignore less important messages.

- Debug -       Lowest priority. Usually names of called methods or callbacks received.
- Verbose -     Low priority messages what the service is doing.
- Info -        Messages about completed tasks.
- Application - Messages about application level events, in this case DFU messages in human-readable form.
- Warning -     Important messages.
- Error -       Highest priority messages with errors.
*/
@objc public enum LogLevel : Int {
    case debug       = 0
    case verbose     = 1
    case info        = 5
    case application = 10
    case warning     = 15
    case error       = 20
    
    public func name() -> String {
        var readableName: String
        switch (self) {
        case .debug:
            readableName = "D"
        case .verbose:
            readableName = "V"
        case .info:
            readableName = "I"
        case .application:
            readableName = "A"
        case .warning:
            readableName = "W"
        case .error:
            readableName = "E"
        }
        return readableName
    }
}

/**
 *  The Logger delegate.
 */
@objc public protocol LoggerDelegate : class {
    
    /**
     This method is called whenever a new log entry is to be saved. The logger implementation should save this or present it to the user.
     
     It is NOT safe to update any UI from this method as multiple threads may log.
     
     - parameter level:   the log level
     - parameter message: the message
     */
    func logWith(_ level: LogLevel, message: String)
}
