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

import Foundation

@objc public enum DFUError : Int {
    // Legacy DFU errors.
    case remoteLegacyDFUSuccess               = 1
    case remoteLegacyDFUInvalidState          = 2
    case remoteLegacyDFUNotSupported          = 3
    case remoteLegacyDFUDataExceedsLimit      = 4
    case remoteLegacyDFUCrcError              = 5
    case remoteLegacyDFUOperationFailed       = 6
    
    // Secure DFU errors (received value + 10 as they overlap legacy errors).
    case remoteSecureDFUSuccess               = 11 // 10 + 1
    case remoteSecureDFUOpCodeNotSupported    = 12 // 10 + 2
    case remoteSecureDFUInvalidParameter      = 13 // 10 + 3
    case remoteSecureDFUInsufficientResources = 14 // 10 + 4
    case remoteSecureDFUInvalidObject         = 15 // 10 + 5
    case remoteSecureDFUSignatureMismatch     = 16 // 10 + 6
    case remoteSecureDFUUnsupportedType       = 17 // 10 + 7
    case remoteSecureDFUOperationNotPermitted = 18 // 10 + 8
    case remoteSecureDFUOperationFailed       = 20 // 10 + 10
    
    // This error will no longer be reported.
    case remoteSecureDFUExtendedError         = 21 // 10 + 11
    // Instead, one of the extended errors below will used.
    case remoteExtendedErrorWrongCommandFormat   = 22 // 20 + 0x02
    case remoteExtendedErrorUnknownCommand       = 23 // 20 + 0x03
    case remoteExtendedErrorInitCommandInvalid   = 24 // 20 + 0x04
    case remoteExtendedErrorFwVersionFailure     = 25 // 20 + 0x05
    case remoteExtendedErrorHwVersionFailure     = 26 // 20 + 0x06
    case remoteExtendedErrorSdVersionFailure     = 27 // 20 + 0x07
    case remoteExtendedErrorSignatureMissing     = 28 // 20 + 0x08
    case remoteExtendedErrorWrongHashType        = 29 // 20 + 0x09
    case remoteExtendedErrorHashFailed           = 30 // 20 + 0x0A
    case remoteExtendedErrorWrongSignatureType   = 31 // 20 + 0x0B
    case remoteExtendedErrorVerificationFailed   = 32 // 20 + 0x0C
    case remoteExtendedErrorInsufficientSpace    = 33 // 20 + 0x0D
    
    // Experimental Buttonless DFU errors (received value + 9000 as they
    // overlap legacy and secure DFU errors).
    case remoteExperimentalButtonlessDFUSuccess               = 9001 // 9000 + 1
    case remoteExperimentalButtonlessDFUOpCodeNotSupported    = 9002 // 9000 + 2
    case remoteExperimentalButtonlessDFUOperationFailed       = 9004 // 9000 + 4
    
    // Buttonless DFU errors (received value + 90 as they overlap legacy
    // and secure DFU errors).
    case remoteButtonlessDFUSuccess            = 91 // 90 + 1
    case remoteButtonlessDFUOpCodeNotSupported = 92 // 90 + 2
    case remoteButtonlessDFUOperationFailed    = 94 // 90 + 4
    
    /// Providing the DFUFirmware is required.
    case fileNotSpecified                     = 101
    /// Given firmware file is not supported.
    case fileInvalid                          = 102
    /// Since SDK 7.0.0 the DFU Bootloader requires the extended Init Packet.
    /// For more details, see:
    /// http://infocenter.nordicsemi.com/topic/com.nordic.infocenter.sdk5.v11.0.0/bledfu_example_init.html?cp=4_0_0_4_2_1_1_3
    case extendedInitPacketRequired           = 103
    /// Before SDK 7.0.0 the init packet could have contained only 2-byte CRC
    /// value, and was optional. Providing an extended one instead would cause
    /// CRC error during validation (the bootloader assumes that the 2 first
    /// bytes of the init packet are the firmware CRC).
    case initPacketRequired                   = 104
    
    case failedToConnect                      = 201
    case deviceDisconnected                   = 202
    case bluetoothDisabled                    = 203
    
    case serviceDiscoveryFailed               = 301
    case deviceNotSupported                   = 302
    case readingVersionFailed                 = 303
    case enablingControlPointFailed           = 304
    case writingCharacteristicFailed          = 305
    case receivingNotificationFailed          = 306
    case unsupportedResponse                  = 307
    /// Error raised during upload when the number of bytes sent is not equal to
    /// number of bytes confirmed in Packet Receipt Notification.
    case bytesLost                            = 308
    /// Error raised when the CRC reported by the remote device does not match.
    /// Service has done 3 attempts to send the data.
    case crcError                             = 309
    
    /// Returns whether the error has been returned by the remote device or
    /// occurred locally.
    var isRemote: Bool {
        return rawValue < 100 || rawValue > 9000
    }
}

/**
 The state of the DFU Service.
 
 - connecting:      Service is connecting to the DFU target.
 - starting:        DFU Service is initializing DFU operation.
 - enablingDfuMode: Service is switching the device to DFU mode.
 - uploading:       Service is uploading the firmware.
 - validating:      The DFU target is validating the firmware.
 - disconnecting:   The iDevice is disconnecting or waiting for disconnection.
 - completed:       DFU operation is completed and successful.
 - aborted:         DFU Operation was aborted.
 */
@objc public enum DFUState : Int {
    case connecting
    case starting
    case enablingDfuMode
    case uploading
    case validating
    case disconnecting
    case completed
    case aborted
    
    public func description() -> String {
        switch self {
        case .connecting:      return "Connecting"
        case .starting:        return "Starting"
        case .enablingDfuMode: return "Enabling DFU Mode"
        case .uploading:       return "Uploading"
        case .validating:      return "Validating"  // This state occurs only in Legacy DFU.
        case .disconnecting:   return "Disconnecting"
        case .completed:       return "Completed"
        case .aborted:         return "Aborted"
        }
    }
}

/**
 *  The progress delegates may be used to notify user about progress updates.
 *  The only method of the delegate is only called when the service is in the
 *  Uploading state.
 */
@objc public protocol DFUProgressDelegate {
    
    /**
     Callback called in the `State.Uploading` state. Gives detailed information
     about the progress and speed of transmission. This method is always called
     at least two times (for 0% and 100%) if upload has started and did not fail.
     
     This method is called in the main thread and is safe to update any UI.
     
     - parameter part: Number of part that is currently being transmitted. Parts
                       start from 1 and may have value either 1 or 2. Part 2 is
                       used only when there were Soft Device and/or Bootloader AND
                       an Application in the Distribution Packet and the DFU target
                       does not support sending all files in a single connection.
                       First the SD and/or BL will be sent, then the service will
                       disconnect, reconnect again to the (new) bootloader and send
                       the Application.
     - parameter totalParts: Total number of parts that are to be send (this is always
                             equal to 1 or 2).
     - parameter progress: The current progress of uploading the current part in
                           percentage (values 0-100).
                           Each value will be called at most once - in case of a large
                           file a value e.g. 3% will be called only once, despite that
                           it will take more than one packet to reach 4%. In case of
                           a small firmware file some values may be ommited.
                           For example, if firmware file would be only 20 bytes you
                           would get a callback 0% (called always) and then 100% when done.
     - parameter currentSpeedBytesPerSecond: The current speed in bytes per second.
     - parameter avgSpeedBytesPerSecond: The average speed in bytes per second.
     */
    @objc func dfuProgressDidChange(for part: Int, outOf totalParts: Int,
                                    to progress: Int,
                                    currentSpeedBytesPerSecond: Double,
                                    avgSpeedBytesPerSecond: Double)
}

/**
 *  The service delegate reports about state changes and errors.
 */
@objc public protocol DFUServiceDelegate {
    
    /**
     Callback called when state of the DFU Service has changed.
     
     This method is called in the delegate queue specified in the
     `DfuServiceInitiator`.
     
     - parameter state: The new state fo the service.
     */
    @objc func dfuStateDidChange(to state: DFUState)
    
    /**
     Called after an error occurred. The device will be disconnected and DFU
     operation has been aborted.
     
     This method is called in the delegate queue specified in the
     `DfuServiceInitiator`.
     
     - parameter error:   The error code.
     - parameter message: Error description.
     */
    @objc func dfuError(_ error: DFUError, didOccurWithMessage message: String)

}
