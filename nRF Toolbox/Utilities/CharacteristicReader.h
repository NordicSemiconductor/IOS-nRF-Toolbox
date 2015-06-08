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
