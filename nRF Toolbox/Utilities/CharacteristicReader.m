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


typedef enum {
    MDER_S_POSITIVE_INFINITY = 0x07FE,
    MDER_S_NaN = 0x07FF,
    MDER_S_NRes = 0x0800,
    MDER_S_RESERVED_VALUE = 0x0801,
    MDER_S_NEGATIVE_INFINITY = 0x0802
} ReservedSFloatValues;
static const UInt32 FIRST_S_RESERVED_VALUE = MDER_S_POSITIVE_INFINITY;

typedef enum {
    MDER_POSITIVE_INFINITY = 0x007FFFFE,
    MDER_NaN = 0x007FFFFF,
    MDER_NRes = 0x00800000,
    MDER_RESERVED_VALUE = 0x00800001,
    MDER_NEGATIVE_INFINITY = 0x00800002
} ReservedFloatValues;
static const UInt32 FIRST_RESERVED_VALUE = MDER_POSITIVE_INFINITY;

static const double reserved_float_values[5] = {INFINITY, NAN, NAN, NAN, -INFINITY};

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
    UInt32 value = (UInt32) CFSwapInt32LittleToHost(*(uint32_t*)*p_encoded_data);
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
    UInt16 tempData = CFSwapInt16LittleToHost(*(uint16_t*)*p_encoded_data);
    
    SInt16 mantissa = tempData & 0x0FFF;
    SInt8 exponent = tempData >> 12;
    
    if (exponent >= 0x0008) {
        exponent = -((0x000F + 1) - exponent);
    }
    
    Float32 output = 0;
    
    if (mantissa >= FIRST_S_RESERVED_VALUE && mantissa <= MDER_S_NEGATIVE_INFINITY)
    {
        output = reserved_float_values[mantissa - FIRST_S_RESERVED_VALUE];
    }
    else
    {
        if (mantissa >= 0x0800)
        {
            mantissa = -((0x0FFF + 1) - mantissa);
        }
        double magnitude = pow(10.0f, exponent);
        output = (mantissa * magnitude);
    }
    
    *p_encoded_data += 2;
    return output;
}

+(Float32)readFloatValue:(uint8_t **)p_encoded_data
{
    SInt32 tempData = (SInt32) CFSwapInt32LittleToHost(*(uint32_t*)*p_encoded_data);
    
    SInt32 mantissa = tempData & 0xFFFFFF;
    SInt8 exponent = tempData >> 24;
    Float32 output = 0;
    
    if (mantissa >= FIRST_RESERVED_VALUE && mantissa <= MDER_NEGATIVE_INFINITY)
    {
        output = reserved_float_values[mantissa - FIRST_RESERVED_VALUE];
    }
    else
    {
        if (mantissa >= 0x800000)
        {
            mantissa = -((0xFFFFFF + 1) - mantissa);
        }
        double magnitude = pow(10.0f, exponent);
        output = (mantissa * magnitude);
    }
    
    *p_encoded_data += 4;
    return output;
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
