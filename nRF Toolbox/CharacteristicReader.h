//
//  CharacteristicReader.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 16/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef union
{
    UInt8 value;
    struct {
        // Reversed order
        UInt8 second : 4;
        UInt8 first : 4;
    };
} Nibble;

@interface CharacteristicReader : NSObject

/*!
 * @brief Inline function for decoding a UInt8 value. It automatically increases the pointer value.
 * @param[in]   p_encoded_data   Buffer where the encoded data is stored.
 * @return      Decoded value.
 */
+ (UInt8) readUInt8Value:(uint8_t**) p_encoded_data;

/*!
 * @brief Inline function for decoding a SInt8 value. It automatically increases the pointer value.
 * @param[in]   p_encoded_data   Buffer where the encoded data is stored.
 * @return      Decoded value.
 */
+ (SInt8) readSInt8Value:(uint8_t**) p_encoded_data;

/*!
 * @brief Inline function for decoding a UInt16 value. It automatically increases the pointer value.
 * @param[in]   p_encoded_data   Buffer where the encoded data is stored.
 * @return      Decoded value.
 */
+ (UInt16) readUInt16Value:(uint8_t**) p_encoded_data;

/*!
 * @brief Inline function for decoding a SInt16 value. It automatically increases the pointer value.
 * @param[in]   p_encoded_data   Buffer where the encoded data is stored.
 * @return      Decoded value.
 */
+ (SInt16) readSInt16Value:(uint8_t**) p_encoded_data;

/*!
 * @brief Inline function for decoding a UInt32 value. It automatically increases the pointer value.
 * @param[in]   p_encoded_data   Buffer where the encoded data is stored.
 * @return      Decoded value.
 */
+ (UInt32) readUInt32Value:(uint8_t**) p_encoded_data;

/*!
 * @brief Inline function for decoding a SInt32 value. It automatically increases the pointer value.
 * @param[in]   p_encoded_data   Buffer where the encoded data is stored.
 * @return      Decoded value.
 */
+ (SInt32) readSInt32Value:(uint8_t**) p_encoded_data;

/*!
 * @brief Inline function for decoding a SFloat value. It automatically increases the pointer value.
 * @param[in]   p_encoded_data   Buffer where the encoded data is stored.
 * @return      Decoded value.
 */
+ (Float32) readSFloatValue:(uint8_t**) p_encoded_data;

/*!
 * @brief Inline function for decoding a Float value. It automatically increases the pointer value.
 * @param[in]   p_encoded_data   Buffer where the encoded data is stored.
 * @return      Decoded value.
 */
+ (Float32) readFloatValue:(uint8_t**) p_encoded_data;

/*!
 * @brief Inline function for decoding a Date & Time value. It automatically increases the pointer value.
 * @param[in]   p_encoded_data   Buffer where the encoded data is stored.
 * @return      Decoded value.
 */
+ (NSDate*) readDateTime:(uint8_t**) p_encoded_data;

/*!
 * @brief Inline function for decoding a Nibble value. It automatically increases the pointer value. A nibble contains a pair of 4-bit values in one byte.
 * @param[in]   p_encoded_data   Buffer where the encoded data is stored.
 * @return      Decoded value.
 */
+ (Nibble) readNibble:(uint8_t**) p_encoded_data;

@end
