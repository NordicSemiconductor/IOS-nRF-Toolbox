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

#import "CharacteristicReader.h"


@implementation CharacteristicReader

+ (UInt8)readUInt8Value:(uint8_t **)p_encoded_data
{
    return *(*p_encoded_data)++;
}

+ (SInt8)readSInt8Value:(uint8_t **)p_encoded_data
{
    return *(*p_encoded_data)++;
}

+ (UInt16)readUInt16Value:(uint8_t **)p_encoded_data
{
    UInt16 value = (UInt16) CFSwapInt16LittleToHost(*(uint16_t*)*p_encoded_data);
    *p_encoded_data += 2;
    return value;
}

+ (SInt16)readSInt16Value:(uint8_t **)p_encoded_data
{
    SInt16 value = (SInt16) CFSwapInt16LittleToHost(*(uint16_t*)*p_encoded_data);
    *p_encoded_data += 2;
    return value;
}

+ (UInt32)readUInt32Value:(uint8_t **)p_encoded_data
{
    UInt32 value = (UInt16) CFSwapInt32LittleToHost(*(uint32_t*)*p_encoded_data);
    *p_encoded_data += 4;
    return value;
}

+ (SInt32)readSInt32Value:(uint8_t **)p_encoded_data
{
    SInt32 value = (SInt32) CFSwapInt32LittleToHost(*(uint32_t*)*p_encoded_data);
    *p_encoded_data += 4;
    return value;
}

+ (Float32)readSFloatValue:(uint8_t **)p_encoded_data
{
    SInt16 tempData = (SInt16) CFSwapInt16LittleToHost(*(uint16_t*)*p_encoded_data);
    SInt8 exponent = (SInt8)(tempData >> 12);
    SInt16 mantissa = (SInt16)(tempData & 0x0FFF);
    *p_encoded_data += 2;
    return (Float32)(mantissa * pow(10, exponent));
}

+(Float32)readFloatValue:(uint8_t **)p_encoded_data
{
    SInt32 tempData = (SInt32) CFSwapInt32LittleToHost(*(uint32_t*)*p_encoded_data);
    SInt8 exponent = (SInt8)(tempData >> 24);
    SInt32 mantissa = (SInt32)(tempData & 0x00FFFFFF);
    *p_encoded_data += 4;
    return (Float32)(mantissa * pow(10, exponent));
}

+(NSDate *)readDateTime:(uint8_t **)p_encoded_data
{
    uint16_t year = [CharacteristicReader readUInt16Value:p_encoded_data];
    uint8_t month = [CharacteristicReader readUInt8Value:p_encoded_data];
    uint8_t day = [CharacteristicReader readUInt8Value:p_encoded_data];
    uint8_t hour = [CharacteristicReader readUInt8Value:p_encoded_data];
    uint8_t min = [CharacteristicReader readUInt8Value:p_encoded_data];
    uint8_t sec = [CharacteristicReader readUInt8Value:p_encoded_data];
    
    NSString * dateString = [NSString stringWithFormat:@"%d %d %d %d %d %d", year, month, day, hour, min, sec];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat: @"yyyy MM dd HH mm ss"];
    return  [dateFormat dateFromString:dateString];
}

+(Nibble)readNibble:(uint8_t **)p_encoded_data
{
    Nibble nibble;
    nibble.value = [CharacteristicReader readUInt8Value:p_encoded_data];
    
    return nibble;
}

@end
