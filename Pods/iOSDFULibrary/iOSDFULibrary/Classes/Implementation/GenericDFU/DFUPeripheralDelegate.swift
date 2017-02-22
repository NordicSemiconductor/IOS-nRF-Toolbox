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

internal protocol BasePeripheralDelegate : class {
    /**
     Method called when the iDevice failed to connect to the given peripheral.
     The DFU operation will be aborter as nothing can be done.
     */
    func peripheralDidFailToConnect()
    
    /**
     Method called after the device got disconnected after sending the whole firmware,
     or was disconnected after an error occurred.
     */
    func peripheralDidDisconnect()
    
    /**
     Method called when the device got unexpectadly disconnected with an error.
     
     - parameter error: the error returned by
     `centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?)`
     */
    func peripheralDidDisconnect(withError error: Error)
    
    /**
     Method called after the DFU operation was aborted and the device got disconnected.
     */
    func peripheralDidDisconnectAfterAborting()
    
    /**
     Method called when an error occurred during the last operation.
     
     - parameter error:   the error type
     - parameter message: details
     */
    func error(_ error: DFUError, didOccurWithMessage message: String)
}

internal protocol DFUPeripheralDelegate : BasePeripheralDelegate {
    /**
     Callback called when the target device got connected and DFU Service and DFU Characteristics were found.
     If DFU Version characteristic were found among them it has also been read.
     */
    func peripheralDidBecomeReady()
    
    /**
     Callback called when the device got disconencted after the current part of
     the firmware has been sent, verified and activated. The iDevice is no longer
     conneted to the target device.
     When there is another part of the firmware to be sent, the delegate should scan for
     a device advertising in DFU Bootloader mode, connect to it. The `peripheralDidBecomeReady()`
     callback will be called again when DFU service will be found in its database.
     */
    func peripheralDidDisconnectAfterFirmwarePartSent()
}
