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

#ifndef nRF_Toolbox_Constants_h
#define nRF_Toolbox_Constants_h

#define is4InchesIPhone ([[UIScreen mainScreen] bounds].size.height == 568)

static NSString * const bgmServiceUUIDString = @"00001808-0000-1000-8000-00805F9B34FB";
static NSString * const bgmGlucoseMeasurementCharacteristicUUIDString = @"00002A18-0000-1000-8000-00805F9B34FB";
static NSString * const bgmGlucoseMeasurementContextCharacteristicUUIDString = @"00002A34-0000-1000-8000-00805F9B34FB";
static NSString * const bgmRecordAccessControlPointCharacteristicUUIDString = @"00002A52-0000-1000-8000-00805F9B34FB";

static NSString * const bpmServiceUUIDString = @"00001810-0000-1000-8000-00805F9B34FB";
static NSString * const bpmBloodPressureMeasurementCharacteristicUUIDString = @"00002A35-0000-1000-8000-00805F9B34FB";
static NSString * const bpmIntermediateCuffPressureCharacteristicUUIDString = @"00002A36-0000-1000-8000-00805F9B34FB";

static NSString * const cscServiceUUIDString = @"00001816-0000-1000-8000-00805F9B34FB";
static NSString * const cscMeasurementCharacteristicUUIDString = @"00002A5B-0000-1000-8000-00805F9B34FB";

static NSString * const rscServiceUUIDString = @"00001814-0000-1000-8000-00805F9B34FB";
static NSString * const rscMeasurementCharacteristicUUIDString = @"00002A53-0000-1000-8000-00805F9B34FB";

static NSString * const hrsServiceUUIDString = @"0000180D-0000-1000-8000-00805F9B34FB";
static NSString * const hrsHeartRateCharacteristicUUIDString = @"00002A37-0000-1000-8000-00805F9B34FB";
static NSString * const hrsSensorLocationCharacteristicUUIDString = @"00002A38-0000-1000-8000-00805F9B34FB";

static NSString * const htsServiceUUIDString = @"00001809-0000-1000-8000-00805F9B34FB";
static NSString * const htsMeasurementCharacteristicUUIDString = @"00002A1C-0000-1000-8000-00805F9B34FB";

static NSString * const proximityImmediateAlertServiceUUIDString = @"00001802-0000-1000-8000-00805F9B34FB";
static NSString * const proximityLinkLossServiceUUIDString = @"00001803-0000-1000-8000-00805F9B34FB";
static NSString * const proximityAlertLevelCharacteristicUUIDString = @"00002A06-0000-1000-8000-00805F9B34FB";

static NSString * const batteryServiceUUIDString = @"0000180F-0000-1000-8000-00805F9B34FB";
static NSString * const batteryLevelCharacteristicUUIDString = @"00002A19-0000-1000-8000-00805F9B34FB";

static NSString * const uartServiceUUIDString = @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
static NSString * const uartTXCharacteristicUUIDString = @"6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
static NSString * const uartRXCharacteristicUUIDString = @"6E400002-B5A3-F393-E0A9-E50E24DCCA9E";

#endif
