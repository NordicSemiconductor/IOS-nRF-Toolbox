# IOS-nRF-Toolbox

The nRF Toolbox is a container app that stores your Nordic Semiconductor apps for Bluetooth Low Energy in one location. 

It contains applications demonstrating the following Bluetooth LE profiles: 

* **Cycling Speed and Cadence**
* **Running Speed and Cadence** 
* **Heart Rate Monitor**
* **Blood Pressure Monitor**
* **Health Thermometer Monitor** 
* **Glucose Monitor**
* **Continuous Glucose Monitor**
* **Proximity Monitor** 
* **Nordic UART**

Additionally, the **HomeKit** profile allows to switch a supported HomeKit device to DFU mode.

### Device Firmware Update (DFU)

The **Device Firmware Update (DFU)** profile allows you to update the application, bootloader and/or the Soft Device image over-the-air (OTA). It is compatible with Nordic Semiconductor nRF5x devices that have the S-Series SoftDevice and bootloader enabled. From version 1.5 onward, the nRF Toolbox has allowed to send the required init packet. More information about the init packet may be found here: [nrf util](https://github.com/NordicSemiconductor/pc-nrfutil).

nRF Toolbox is using the iOSDFULibrary framework, available here: [IOS-Pods-DFU-Library](https://github.com/NordicSemiconductor/IOS-Pods-DFU-Library). The library is packaged with the project so no extra work is needed, if you would like to manually update it or modify it, it is bundled via cocoapods so a simple `pod update` will handle updating the library for you. 

The DFU profile has the following features:
- Scans for devices that are in DFU mode.
- Connects to devices in DFU mode and uploads the selected firmware (Softdevice, Bootloader and/or application).
- Allows ZIP, HEX or BIN file updates.
- Allows to update a Softdevice and/or bootloader and application from a distribution ZIP file automatically.
- Pause, resume, and cancel firmware updates.
- Includes pre-installed examples that consist of the Bluetooth LE services and Doorlock firmware from Nordic HK SDK 6.1.

### Secure Device Firmware Update (Secure DFU)

The **Secure Device Firmware Update (Secure DFU)** profile allows you to **securely** update your Nordic Semiconductor nRF5x S-Seriese devices.
This works by verifying that your firmware files are signed by the vendor that released the code and has not been tampered with, also this means that the peripherals will only accept updates from
the intended developers and reject any firmwares that are not properly signed with the matching key.

As an applications developer, the frontend for the DFU Library is agnostic of the DFU protocol in use, so there are no changes to be done on the mobile application's side to support Secure DFU. 

### Requirements

- iOS 9.0 and above.
- Compatible with nRF5x devices with S-Series Softdevice and DFU Bootloader flashed.

### Resources

- nRF51 and nRF52 Development kits can be ordered from [nordicsemi.com/eng/Buy-Online](http://www.nordicsemi.com/eng/Buy-Online).
- The SDK and SoftDevices are available online at [developer.nordicsemi.com](http://developer.nordicsemi.com).
