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

+(NSUInteger)calculateBinLength:(NSData*)hex
{
    if (hex == nil || hex.length == 0)
    {
        return 0;
    }
    
    NSUInteger binLength = 0;
    const NSUInteger hexLength = hex.length;
    const Byte* pointer = (const Byte*)hex.bytes;
    
    do
    {
        const Byte semicollon = *pointer++;
        
        // Validate - each line of the file must have a semicollon as a firs char
        if (semicollon != ':')
        {
            return 0;
        }
        
        const UInt8 reclen = [IntelHex2BinConverter readByte:pointer]; pointer += 2;
        pointer += 4;   // Skip the offset
        const UInt8 rectype = [IntelHex2BinConverter readByte:pointer]; pointer += 2;
        
        // If record type is Data Record (rectype = 0), add it's length
        if (rectype == 0)
        {
            binLength += reclen;
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
        pointer += 4;   // Skip the offset
        const UInt8 rectype = [IntelHex2BinConverter readByte:pointer]; pointer += 2;
        
        // If record type is Data Record (rectype = 0), copy data to output buffer
        if (rectype == 0)
        {
            for (int i = 0; i < reclen; i++)
            {
                *output++ = [IntelHex2BinConverter readByte:pointer]; pointer += 2;
            }
        }
        else
        {
            pointer += (reclen << 1);  // Skip the data when calculating length
        }
        
        pointer += 2;   // Skip the checksum
        // Skip new line
        if (*pointer == '\r') pointer++;
        if (*pointer == '\n') pointer++;
    } while (pointer != hex.bytes + hexLength);
    
    return [NSData dataWithBytesNoCopy:bytes length:binLength];
}

@end
