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

static NSString * const rscServiceUUID = @"00001814-0000-1000-8000-00805F9B34FB";
static NSString * const rscMeasurementCharacteristicUUID = @"00002A53-0000-1000-8000-00805F9B34FB";

static NSString * const batteryServiceUUID = @"0000180F-0000-1000-8000-00805F9B34FB";
static NSString * const batteryLevelCharacteristicUUID = @"00002A19-0000-1000-8000-00805F9B34FB";

#endif
