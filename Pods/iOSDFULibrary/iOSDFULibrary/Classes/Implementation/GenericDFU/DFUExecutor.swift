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

typealias DelegateCallback = (DFUServiceDelegate) -> Void

internal protocol BaseExecutorAPI : class, DFUController {
    
    /**
     Starts the DFU operation.
     */
    func start()
}

internal protocol BaseDFUExecutor : BaseExecutorAPI, BasePeripheralDelegate {
    associatedtype DFUPeripheralType : BaseDFUPeripheralAPI
    
    /// Target peripheral object.
    var peripheral: DFUPeripheralType { get }
    /// The DFU Service Initiator instance that was used to start the service.
    var initiator: DFUServiceInitiator { get }
    /// The optional logger delegate.
    var logger: LoggerHelper { get }
    /// If an error occurred it is set as this variable. It will be reported to the user when the device gets disconnected.
    var error: (error: DFUError, message: String)? { set get }
}

extension BaseDFUExecutor {
    
    // MARK: - DFU Controller API
    
    func pause() -> Bool {
        return peripheral.pause()
    }
    
    func resume() -> Bool {
        return peripheral.resume()
    }
    
    func abort() -> Bool {
        return peripheral.abort()
    }
    
    // MARK: - BasePeripheralDelegate API
    
    func peripheralDidFailToConnect() {
        delegate {
            $0.dfuError(.failedToConnect, didOccurWithMessage: "Device failed to connect")
        }
        // Release the cyclic reference
        peripheral.destroy()
    }
    
    func peripheralDidDisconnect() {
        // The device is now disconnected. Check if there was an error that needs to be reported now
        delegate {
            if let error = self.error {
                $0.dfuError(error.error, didOccurWithMessage: error.message)
            } else {
                $0.dfuError(.deviceDisconnected, didOccurWithMessage: "Device disconnected unexpectedly")
            }
        }
        // Release the cyclic reference
        peripheral.destroy()
    }
    
    func peripheralDidDisconnect(withError error: Error) {
        delegate {
            $0.dfuError(.deviceDisconnected, didOccurWithMessage: "\(error.localizedDescription) (code: \((error as NSError).code))")
        }
        // Release the cyclic reference
        peripheral.destroy()
    }
    
    func peripheralDidDisconnectAfterAborting() {
        delegate {
            $0.dfuStateDidChange(to: .aborted)
        }
        // Release the cyclic reference
        peripheral.destroy()
    }
    
    func error(_ error: DFUError, didOccurWithMessage message: String) {
        // Save the error. It will be reported when the device disconnects
        if self.error == nil {
            self.error = (error, message)
            peripheral.resetDevice()
        }
    }
    
    // MARK: - Helper functions
    
    /// Calls the delegate method on the delegate queue given in the initiator.
    func delegate(callback: @escaping DelegateCallback) {
        if let delegate = initiator.delegate {
            initiator.delegateQueue.async {
                callback(delegate)
            }
        }
    }
}

// MARK: -

internal protocol DFUExecutorAPI : BaseExecutorAPI {
    
    /// Required constructor.
    init(_ initiator: DFUServiceInitiator, _ logger: LoggerHelper)
}

internal protocol DFUExecutor : DFUExecutorAPI, BaseDFUExecutor, DFUPeripheralDelegate where DFUPeripheralType: DFUPeripheralAPI {
    
    /// The firmware to be sent over-the-air.
    var firmware: DFUFirmware { get }
}

extension DFUExecutor {
    
    // MARK: - DFUPeripheralDelegate API
    
    func peripheralDidDisconnectAfterFirmwarePartSent() -> Bool {
        // Check if there is another part of the firmware that has to be sent
        if firmware.hasNextPart() {
            firmware.switchToNextPart()
            delegate {
                $0.dfuStateDidChange(to: .connecting)
            }
            return true
        }
        // If not, we are done here. Congratulations!
        delegate {
            $0.dfuStateDidChange(to: .completed)
        }
            
        // Release the cyclic reference
        peripheral.destroy()
        return false
    }
}
