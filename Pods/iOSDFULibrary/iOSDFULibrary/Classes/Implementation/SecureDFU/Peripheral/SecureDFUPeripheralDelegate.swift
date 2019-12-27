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

internal protocol SecureDFUPeripheralDelegate : DFUPeripheralDelegate {
    
    /**
     Callback called when DFU Control Point notifications were enabled successfully.
     */
    func peripheralDidEnableControlPoint()
    
    /**
     Callback when Command Object Info has been received from the peripheral.
     
     - parameter maxLen: The maximum size of the Init Packet in bytes.
     - parameter offset: Number of bytes of Init Packet already sent, for example during
                         last DFU operation. This resets to 0 on Create Command Object or
                         when the DFU operation completes.
     - parameter crc: The CRC-32 calculated from the 'offset' bytes. This may be used to
                      calculate if the stored Init packet matches the one being sent now.
                      If crc matches the operation may be resumed, if not a new Command
                      Object should be created and DFU should start over.
     */
    func peripheralDidSendCommandObjectInfo(maxLen: UInt32, offset: UInt32, crc: UInt32)

    /**
     Callback when Data Object Info has been received from the peripheral.
     
     - parameter maxLen: The maximum size of a single data object in bytes. A firmware
                         may be sent in multiple objects.
     - parameter offset: Number of bytes of data already sent (in total, not only the
                         last object), for example during last DFU operation.
                         Sending Create Data will rewind the offset to the last executed
                         data object. This resets to 0 on Create Command Object or when
                         the DFU operation completes.
     - parameter crc: The CRC-32 calculated from the 'offset' bytes. This may be used
                      to calculate if the stored data matches the firmware being sent now.
                      If crc matches the operation may be resumed, if not a new Command
                      Object should be created and DFU should start over.
     */
    func peripheralDidSendDataObjectInfo(maxLen: UInt32, offset: UInt32, crc: UInt32)

    /**
     Callback when Command Object was created.
     */
    func peripheralDidCreateCommandObject()

    /**
     Callback when Data Object was created.
     */
    func peripheralDidCreateDataObject()
    
    /**
     Callback when Packet Receipt Notifications were set or disabled.
     */
    func peripheralDidSetPRNValue()

    /**
     Callback when init packet is sent. Actually this method is called when Init packet data
     were added to the outgoing buffer on iDevice and will be sent as soon as possible, not when
     the peripheral actually received them, as they are called with Write Without Response and
     no such callback is generated.
     */
    func peripheralDidReceiveInitPacket()
    
    /**
     Callback when Checksum was received after sending Calculate Checksum request.
     
     - parameter offset: Number of bytes of the current objecy received by the peripheral.
     - parameter crc:    CRC-32 calculated rom those received bytes.
    */
    func peripheralDidSendChecksum(offset: UInt32, crc: UInt32)

    /**
     Callback when Execute Object command completes with status success. After receiving this
     callback the device may reset if the whole firmware was sent.
     */
    func peripheralDidExecuteObject()
    
    /**
     Callback when the Command Object has been rejected by the target device by sending a
     Remote DFU Error, but the firmware contains a second part that the service should try to
     send. Perhaps the SoftDevice and Bootloader were sent before and the target rejects second
     update (bootloader can't be updated with one with the same FW version).
     Application update should succeeded in such case.
     
     - parameter error:   The error that occurred.
     - parameter message: The error message.
     */
    func peripheralRejectedCommandObject(withError error: DFUError, andMessage message: String)

    /**
     Callback when Data Object was successfully sent.
     */
    func peripheralDidReceiveObject()
}
