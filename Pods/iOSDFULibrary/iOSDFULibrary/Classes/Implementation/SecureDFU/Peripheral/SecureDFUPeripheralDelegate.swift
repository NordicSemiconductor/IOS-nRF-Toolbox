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

internal protocol SecureDFUPeripheralDelegate {
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
     Callback when Object info command read is completed
     */
    func objectInfoReadCommandCompleted(_ maxLen : UInt32, offset : UInt32, crc :UInt32 )

    /**
     Callback when Object info data read is completed
     */
    func objectInfoReadDataCompleted(_ maxLen : UInt32, offset : UInt32, crc :UInt32 )

    /**
     Callback when Object Command is created
     */
    func objectCreateCommandCompleted(_ data : Data?)

    /**
     Callback when Object Data is created
     */
    func objectCreateDataCompleted(_ data : Data?)
    
    /**
     Callback when PRN is set
     */
    func setPRNValueCompleted()

    /**
     Callback when init packet is sent
     */
    func initPacketSendCompleted()
    
    /**
     Callback when Checksum command is completed
    */
    func calculateChecksumCompleted(_ offset: UInt32, CRC: UInt32)

    /**
     Callback when Execute last object command completes
     */
    func executeCommandCompleted()

    /**
     Callback when firmware is successfully sent
     */
    func firmwareSendComplete()

    /**
     Method called after the DFU operation was aborted and the device got disconnected.
     */
    func onAborted()

    /**
     Callback when firmware chunk is successfully sent
     */
    func firmwareChunkSendcomplete()
    
    /**
     Method called when the iDevice failed to connect to the given peripheral.
     The DFU operation will be aborter as nothing can be done.
     */
    func didDeviceFailToConnect()
    
    /**
     Method called after the device got disconnected after sending the whole firmware,
     or was disconnected after an error occurred.
     */
    func peripheralDisconnected()
    
    /**
     Method called when the device got unexpectadly disconnected with an error.
     
     - parameter error: the error returned by 
     `centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?)`
     */
    func peripheralDisconnected(withError anError : NSError)
    
    /**
     Method called when an error occurrs in the last operation.
     
     - parameter error:   the error type
     - parameter message: details
     */
    func onErrorOccured(withError anError:SecureDFUError, andMessage aMessage:String)
}
