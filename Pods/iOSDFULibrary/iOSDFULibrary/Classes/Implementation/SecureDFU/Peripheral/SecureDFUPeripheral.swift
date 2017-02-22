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
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES LOSS OF USE, DATA, OR PROFITS OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import CoreBluetooth

internal class SecureDFUPeripheral : BaseCommonDFUPeripheral<SecureDFUExecutor, SecureDFUService> {
    
    // MARK: - Peripheral API
    
    override var requiredServices: [CBUUID]? {
        return [SecureDFUService.UUID]
    }
    
    override func isInitPacketRequired() -> Bool {
        // Init packet is obligatory in Secure DFU
        return true
    }
    
    // MARK: - Implementation
    
    /**
     Enables notifications on DFU Control Point characteristic.
     */
    func enableControlPoint() {
        dfuService!.enableControlPoint(
            onSuccess: { self.delegate?.peripheralDidEnableControlPoint() },
            onError: defaultErrorCallback
        )
    }
    
    override func isInApplicationMode(_ forceDfu: Bool) -> Bool {
        let applicationMode = dfuService!.isInApplicationMode() ?? !forceDfu
        
        if applicationMode {
            logger.w("Application with buttonless update found")
        }
        
        return applicationMode
    }
    
    /**
     Switches target device to the DFU Bootloader mode using either the 
     experimental or final Buttonless DFU feature. The experimental buttonless DFU from SDK 12 must be
     enabled explicitly in DFUServiceInitiator.
     */
    func jumpToBootloader() {
        jumpingToBootloader = true
        newAddressExpected = dfuService!.newAddressExpected
        dfuService!.jumpToBootloaderMode(
            // onSuccess the device gets disconnected and centralManager(_:didDisconnectPeripheral:error) will be called
            onError: { (error, message) in
                self.jumpingToBootloader = false
                self.delegate?.error(error, didOccurWithMessage: message)
            }
        )
    }
    
    /**
     Reads Data Object Info in order to obtain current status and the maximum object size.
     */
    func readDataObjectInfo() {
        dfuService!.readDataObjectInfo(
            onReponse: { (response) in
                self.delegate?.peripheralDidSendDataObjectInfo(maxLen: response!.maxSize!, offset: response!.offset!, crc: response!.crc!)
            },
            onError: defaultErrorCallback
        )
    }
    
    /**
     Reads Command Object Info in order to obtain current status and the maximum object size.
     */
    func readCommandObjectInfo() {
        dfuService!.readCommandObjectInfo(
            onReponse: { (response) in
                self.delegate?.peripheralDidSendCommandObjectInfo(maxLen: response!.maxSize!, offset: response!.offset!, crc: response!.crc!)
            },
            onError: defaultErrorCallback
        )
    }
    
    /**
     Creates data object with given length.
     
     - parameter aLength: exact size of the object
     */
    func createDataObject(withLength aLength: UInt32) {
        dfuService!.createDataObject(withLength: aLength,
             onSuccess: { self.delegate?.peripheralDidCreateDataObject() },
             onError: defaultErrorCallback
        )
    }
    
    /**
     Creates command object with given length.
     
     - parameter aLength: exact size of the object
     */
    func createCommandObject(withLength aLength: UInt32) {
        dfuService!.createCommandObject(withLength: aLength,
            onSuccess: { self.delegate?.peripheralDidCreateCommandObject() },
            onError: defaultErrorCallback
        )
    }
    
    /**
     Sends a given range of data from the firmware.
     
     - parameter aRange:            given range of the firmware will be sent
     - parameter aFirmware:         the firmware from with part is to be sent
     - parameter aProgressDelegate: an optional progress delegate
     */
    func sendNextObject(from aRange: Range<Int>, of aFirmware: DFUFirmware, andReportProgressTo aProgressDelegate: DFUProgressDelegate?) {
        dfuService!.sendNextObject(from: aRange, of: aFirmware, andReportProgressTo: aProgressDelegate,
            onSuccess: { self.delegate?.peripheralDidReceiveObject() },
            onError: defaultErrorCallback
        )
    }
    
    /**
     Sets the Packet Receipt Notification value. 0 disables the PRN procedure. On iOS the value may not be greater than ~20 or equal to 0
     if more than ~20 are to be sent or a buffer overflow error may occur.
     This library sends the Init packet without PRNs, but that's only because of the Init packet is small enough.
     
     - parameter aValue:  Packet Receipt Notification value (0 to disable PRNs)
     */
    func setPRNValue(_ aValue: UInt16 = 0) {
        dfuService!.setPacketReceiptNotificationValue(aValue,
            onSuccess: { self.delegate?.peripheralDidSetPRNValue() },
            onError: defaultErrorCallback
        )
    }
    
    /**
     Sends Init packet. This method is synchronuous and calls delegate's peripheralDidReceiveInitPacket() method ater the given data are sent.
     
     - parameter packetData: data to be sent as Init Packet
     */
    func sendInitPacket(_ packetData: Data){
        // This method is synchronuous.
        // It sends all bytes of init packet in up-to-20-byte packets.
        // The init packet may not be too long as sending > ~15 packets without PRNs may lead to buffer overflow.
        dfuService!.sendInitPacket(withdata: packetData)
        self.delegate?.peripheralDidReceiveInitPacket()
    }
    
    /**
     Sends Calculate Checksum request.
     */
    func sendCalculateChecksumCommand() {
        dfuService!.calculateChecksumCommand(
            onSuccess: { (response) in self.delegate?.peripheralDidSendChecksum(offset: response!.offset!, crc: response!.crc!) },
            onError: defaultErrorCallback
        )
    }
    
    /**
     Sends Execute command.
     
     - parameter activating: if the parameter is set to true the service will assume that the whole firmware was sent
     and the device will disconnect on its own on Execute command. Delegate's onTransferComplete event will be called when
     the disconnect event is receviced.
     */
    func sendExecuteCommand(andActivateIf activating: Bool = false) {
        self.activating = activating
        dfuService!.executeCommand(
            onSuccess: { self.delegate?.peripheralDidExecuteObject() },
            onError: defaultErrorCallback
        )
    }
}
