//
//  Constants.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 13/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

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

//static NSString * const dfuServiceUUIDString = @"00001530-1212-EFDE-1523-785FEABCD123";
//static NSString * const dfuControlPointCharacteristicUUIDString = @"00001531-1212-EFDE-1523-785FEABCD123";
//static NSString * const dfuPacketCharacteristicUUIDString = @"00001532-1212-EFDE-1523-785FEABCD123";

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

#endif
