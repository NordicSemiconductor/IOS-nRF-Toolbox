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

internal protocol DFUStarterPeripheralDelegate : BasePeripheralDelegate {
    /**
     Callback called when a DFU service has been found on a remote device.
     - returns: The executor type based on the found DFU Service: SecureDFUExecutor or LegacyDFUExecutor
     */
    func peripheralDidSelectedExecutor(_ ExecutorType: DFUExecutorAPI.Type)
}

/**
 This class has a responsibility to connect to a given peripheral and determin which DFU implementation should be used
 based on the services found on the device.
 */
internal class DFUServiceSelector : BaseDFUExecutor, DFUStarterPeripheralDelegate {
    typealias DFUPeripheralType = DFUStarterPeripheral
    
    internal let initiator:  DFUServiceInitiator
    internal let controller: DFUServiceController
    internal let peripheral: DFUStarterPeripheral
    internal var error: (error: DFUError, message: String)?
    
    init(initiator: DFUServiceInitiator, controller: DFUServiceController) {
        self.initiator  = initiator
        self.controller = controller
        self.peripheral = DFUStarterPeripheral(initiator)
        
        self.peripheral.delegate = self
    }
    
    func start() {
        DispatchQueue.main.async(execute: {
            self.delegate?.dfuStateDidChange(to: .connecting)
        })
        peripheral.start()
    }
    
    func peripheralDidSelectedExecutor(_ ExecutorType: DFUExecutorAPI.Type) {
        // Release the cyclic reference
        peripheral.destroy()
        
        let executor = ExecutorType.init(initiator)
        controller.executor = executor
        executor.start()
    }
}
