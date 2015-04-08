/*
 * Copyright (c) 2015, Nordic Semiconductor
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

#import "IntelHex2BinConverter.h"

@implementation IntelHex2BinConverter

+(const Byte)ascii2char:(const Byte*)ascii
{
    if (*ascii >= 'A')
        return *ascii - 0x37;
    
    if (*ascii >= '0')
        return *ascii - '0';
    return -1;
}

+(const Byte)readByte:(const Byte*)pointer
{
    Byte first = [IntelHex2BinConverter ascii2char:pointer];
    Byte second = [IntelHex2BinConverter ascii2char:pointer + 1];
    
    return (first << 4) | second;
}

+(const UInt16)readAddress:(const Byte*)pointer
{
    Byte msb = [IntelHex2BinConverter readByte:pointer];
    Byte lsb = [IntelHex2BinConverter readByte:pointer + 2];
    
    return (msb << 8) | lsb;
}

+(NSUInteger)calculateBinLength:(NSData*)hex
{
    if (hex == nil || hex.length == 0)
    {
        return 0;
    }
    
    NSUInteger binLength = 0;
    const NSUInteger hexLength = hex.length;
    const Byte* pointer = (const Byte*)hex.bytes;
    UInt32 lastBaseAddress = 0;
    
    do
    {
        const Byte semicollon = *pointer++;
        
        // Validate - each line of the file must have a semicollon as a firs char
        if (semicollon != ':')
        {
            return 0;
        }
        
        const UInt8 reclen = [IntelHex2BinConverter readByte:pointer]; pointer += 2;
        const UInt16 offset = [IntelHex2BinConverter readAddress:pointer]; pointer += 4;
        const UInt8 rectype = [IntelHex2BinConverter readByte:pointer]; pointer += 2;
        
        switch (rectype) {
            case 0x04: {
                // Only consistent hex files are supported. If there is a jump to non-following ULBA address skip the rest of the file
                const UInt32 newULBA = [IntelHex2BinConverter readAddress:pointer];
                if (binLength > 0 && newULBA != (lastBaseAddress >> 16) + 1)
                    return binLength;
                lastBaseAddress = newULBA << 16;
                break;
            }
            case 0x02: {
                // The same with Extended Segment Address. The calculated ULBA must not be greater than the last one + 1
                const UInt32 newSBA = [IntelHex2BinConverter readAddress:pointer] << 4;
                if (binLength > 0 && (newSBA >> 16) != (lastBaseAddress >> 16) + 1)
                    return binLength;
                lastBaseAddress = newSBA;
                break;
            }
            case 0x00:
                // If record type is Data Record (rectype = 0), add it's length (only it the address is >= 0x1000, MBR is skipped)
                if (lastBaseAddress + offset >= 0x1000)
                    binLength += reclen;
            default:
                break;
        }
        
        pointer += (reclen << 1);  // Skip the data when calculating length
        pointer += 2;   // Skip the checksum
        // Skip new line
        if (*pointer == '\r') pointer++;
        if (*pointer == '\n') pointer++;
    } while (pointer != hex.bytes + hexLength);
    
    return binLength;
}

+(NSData *)convert:(NSData *)hex
{
    const NSUInteger binLength = [IntelHex2BinConverter calculateBinLength:hex];
    const NSUInteger hexLength = hex.length;
    const Byte* pointer = (const Byte*)hex.bytes;
    NSUInteger bytesCopied = 0;
    UInt32 lastBaseAddress = 0;
    
    Byte* bytes = malloc(sizeof(Byte) * binLength);
    Byte* output = bytes;
    
    do
    {
        const Byte semicollon = *pointer++;
        
        // Validate - each line of the file must have a semicollon as a firs char
        if (semicollon != ':')
        {
            free(bytes);
            return nil;
        }
        
        const UInt8 reclen = [IntelHex2BinConverter readByte:pointer]; pointer += 2;
        const UInt16 offset = [IntelHex2BinConverter readAddress:pointer]; pointer += 4;
        const UInt8 rectype = [IntelHex2BinConverter readByte:pointer]; pointer += 2;
        
        switch (rectype) {
            case 0x04: {
                const UInt32 newULBA = [IntelHex2BinConverter readAddress:pointer]; pointer += 4;
                if (bytesCopied > 0 && newULBA != (lastBaseAddress >> 16) + 1)
                    return [NSData dataWithBytesNoCopy:bytes length:bytesCopied];
                lastBaseAddress = newULBA << 16;
                break;
            }
            case 0x02: {
                const UInt32 newSBA = [IntelHex2BinConverter readAddress:pointer] << 4; pointer += 4;
                if (bytesCopied > 0 && (newSBA >> 16) != (lastBaseAddress >> 16) + 1)
                    return [NSData dataWithBytesNoCopy:bytes length:bytesCopied];
                lastBaseAddress = newSBA;
                break;
            }
            case 0x00:
                // If record type is Data Record (rectype = 0), copy data to output buffer
                // Skip data below 0x1000 address (MBR)
                if (lastBaseAddress + offset >= 0x1000)
                {
                    for (int i = 0; i < reclen; i++)
                    {
                        *output++ = [IntelHex2BinConverter readByte:pointer]; pointer += 2;
                        bytesCopied++;
                    }
                }
                else
                {
                    pointer += (reclen << 1);  // Skip the data
                }
                break;
            default:
                pointer += (reclen << 1);  // Skip the irrelevant data
                break;
        }
        
        pointer += 2;   // Skip the checksum
        // Skip new line
        if (*pointer == '\r') pointer++;
        if (*pointer == '\n') pointer++;
    } while (pointer != hex.bytes + hexLength);
    
    return [NSData dataWithBytesNoCopy:bytes length:bytesCopied];
}

@end
