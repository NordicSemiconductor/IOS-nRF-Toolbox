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

internal protocol DFUPeripheralDelegate {    
    /**
     Callback called when the target device got connected and DFU Service and DFU Characteristics were found.
     If DFU Version characteristic were found among them it has also been read.
     */
    func onDeviceReady()
    
    /**
     Callback called when DFU Control Point notifications were enabled successfully.
     The delegate should now decide whether to jump to the DFU Bootloader mode or to proceed with DFU operation.
     */
    func onControlPointEnabled()
    
    /**
     Callback called when the target DFU device returned Not Supported after sending Start DFU command
     with a firmware type. It means, that an older version of DFU Bootloader is running on the device, 
     which allows only the Application to be updated.
     If the firmware contains only an application, the service may use the DFU v.1 protocol.
     Otherwise, the DFU can't be continued and the device will be disconnected.
     */
    func onStartDfuWithTypeNotSupported()
    
    /**
     Callback called when the target DFU device returned Invalid state after sending Start DFU command
     this usually means that the device has been interrupted while uploading the firmware and needs to 
     strat from scratch, in theory this should be able to just resume, but in practice there are some
     issues that arise, like not being able to verify if the same firmware file is being sent, etc..
     it is better to simply send a reset command and start from scratch on invalid state cases.
     */
    func onDeviceReportedInvalidState()
    
    /**
     Callback called after the Start DFU command (v.2 or v.1) has been successfully sent and a Success
     response was received. The delegate should now initialize sending the Init Packet (if provided),
     or start sending firmware (in other case).
     */
    func onStartDfuSent()
    
    /**
     Callback called after the Init Packet has been sent and Success response was received.
     The delegate is allowed to start sending the firmware now.
     */
    func onInitPacketSent()
    
    /**
     Callback called after the current part of the firmware was successfully sent to the DFU target device.
     THe delegate should send Validate Firmware command.
     */
    func onFirmwareSent()
    
    /**
     Callback called when the target DFU device returned Success on validation request.
     The new firmware has been accepted. Activate and Reset command may now be sent,
     which will cause the device to disconnect from us.
     */
    func onFirmwareVerified()
    
    /**
     Callback called when the device got disconencted after the current part of
     the firmware has been sent, verified and activated. The iDevice is no longer 
     conneted to the target device.
     When there is another part of the firmware to be sent, the delegate should scan for
     a device advertising in DFU Bootloader mode, connect to it. The `onDeviceReady()`
     callback will be called again when DFU service will be found in its database.
     */
    func onTransferComplete()
    
    /**
     Method called after the DFU operation was aborted and the device got disconnected.
     */
    func onAborted()
    
    /**
     Method called when the iDevice failed to connect to the given peripheral.
     The DFU operation will be aborter as nothing can be done.
     */
    func didDeviceFailToConnect()
    
    /**
     Method called after the device got disconnected after sending the whole firmware,
     or was disconnected after an error occurred.
     */
    func didDeviceDisconnect()
    
    /**
     Method called when the device got unexpectadly disconnected with an error.
     
     - parameter error: the error returned by 
     `centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?)`
     */
    func didDeviceDisconnectWithError(_ error:Error)
    
    /**
     Method called when an error occurred during the last operation.
     
     - parameter error:   the error type
     - parameter message: details
     */
    func didErrorOccur(_ error:DFUError, withMessage message:String)
}
