//
//  CharacteristicReader.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 16/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

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
