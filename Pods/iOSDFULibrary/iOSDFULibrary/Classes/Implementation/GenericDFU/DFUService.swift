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

import CoreBluetooth

internal typealias Callback = (Void) -> Void
internal typealias ErrorCallback = (_ error: DFUError, _ withMessage: String) -> Void
internal typealias ProgressCallback = (_ bytesReceived: UInt32) -> Void

internal protocol DFUService : DFUController {
    /// The UUID of the service
    static var UUID: CBUUID { get }
    /// The target DFU Peripheral
    var targetPeripheral: DFUPeripheralAPI? { get set }
    
    /**
     Returns true if given service matches this service UUID
     - parameter service: the service to check
     - returns: true if the service can be insanced based on the given service, false otherwise
     */
    static func matches(_ service: CBService) -> Bool
    
    /**
     Required constructor of a service.
     */
    init(_ service: CBService, _ logger: LoggerHelper)
    
    /**
     Discovers characteristics in the DFU Service. This method also reads the DFU Version characteristic if such found.
     */
    func discoverCharacteristics(onSuccess success: @escaping Callback, onError report: @escaping ErrorCallback)
    
    /**
     This method makes sure all the references are released so that ARC can remove the objects.
     */
    func destroy()
}
