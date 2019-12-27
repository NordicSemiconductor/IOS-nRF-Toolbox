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

internal protocol DFUController {
    
    /**
     Call this method to pause uploading during the transmition process.
     The transmition can be resumed only when connection remains. If service
     has already started sending firmware data it will pause after receiving
     next Packet Receipt Notification. Otherwise` it will continue to send
     Op Codes and pause before sending the first bytes of the firmware. With
     Packet Receipt Notifications disabled it is the only moment when upload
     may be paused.
     
     - returns: `True` if DFU operation was paused, `false` otherwise.
     */
    func pause() -> Bool
    
    /**
     Call this method to resume the paused transffer, otherwise does nothing.
     
     - returns: `True` if DFU operation was resumed, `false` otherwise.
     */
    func resume() -> Bool
    
    /**
     Aborts the upload. The phone will disconnect from peripheral. The peripheral
     will try to recover the last firmware. Might, restart in the Bootloader mode
     if the application has been removed.
     
     Abort (Reset) command will be sent instead of a next Op Code, or after
     receiving a Packet Receipt Notification (PRN). It PRM procedure is disabled
     it will continue until the whole firmware is sent and then Reset will be
     sent instead of Verify Firmware op code.
     
     - returns: `True` if DFU operation was aborted, `false` otherwise.
     */
    func abort() -> Bool
}
