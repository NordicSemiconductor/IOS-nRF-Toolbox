//
//  IntelHex2BinConverter.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 15/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

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
    UInt16 lastULBA = 0;
    
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
                // Only consistent hex files are supported. If there is a jump (0x04) to non-following address skip the rest of the file
                const UInt16 newULBA = [IntelHex2BinConverter readAddress:pointer];
                if (binLength > 0 && newULBA != lastULBA + 1)
                    return binLength;
                lastULBA = newULBA;
                break;
            }
            case 0x02:
                // Should here be the same as for 0x04?
                break;
            case 0x00:
                // If record type is Data Record (rectype = 0), add it's length (only it the address is >= 0x1000, MBR is skipped)
                if ((lastULBA << 16) + offset >= 0x1000)
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
    UInt16 lastULBA = 0;
    
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
                // Only consistent hex files are supported. If there is a jump (0x04) to non-following address skip the rest of the file
                const UInt16 newULBA = [IntelHex2BinConverter readAddress:pointer]; pointer += 4;
                if (bytesCopied > 0 && newULBA != lastULBA + 1)
                    return [NSData dataWithBytesNoCopy:bytes length:bytesCopied];
                lastULBA = newULBA;
                break;
            }
            case 0x00:
                // If record type is Data Record (rectype = 0), copy data to output buffer
                // Skip data below 0x1000 address (MBR)
                if ((lastULBA << 16) + offset >= 0x1000)
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
            case 0x02:
                // Should here be the same as for 0x04?
            default:
                pointer += (reclen << 1);  // Skip the data when calculating length
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
