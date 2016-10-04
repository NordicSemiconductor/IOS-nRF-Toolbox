# IOS-nRF-Toolbox

The nRF Toolbox is a container app that stores your Nordic Semiconductor apps for Bluetooth Smart in one location. 

New in v4.1:
* The application is now Fully migrated to Swift3.0
* Bugfix: Importing of distribution packets via email no longer crashes
* Bugfix: Glucose monitor demo no longer crashes/displays incorrect timestamps when the device uses the 12 hour format locale
* Bugfix: Glucose monitor demo no longer duplicates data on the last row when refresh button is tapped

New in v4.0:
* The application is fully migrated to Swift2.2
* Added **Continuous Glucose Monitor** profile support
* The Application now uses the Cocoapods version of our DFU Library. See [cocoapods/iOSDFULibrary](https://cocoapods.org/pods/iOSDFULibrary)
* Minor bugfixes in characteristics reading on some profiles

New in v3.0:
* The application uses DFU Library, instead of having it's own implementation. See [IOS-DFU-Library](https://github.com/NordicSemiconductor/IOS-DFU-Library).

New in v2.5:
* Refreshed Look & Feel
* Better user experience in DFU and UART profiles
* Bug fixes

It contains applications demonstrating Bluetooth Smart profiles: 
* **Cycling Speed and Cadence**, 
* **Running Speed and Cadence**, 
* **Heart Rate Monitor**, 
* **Blood Pressure Monitor**, 
* **Health Thermometer Monitor**, 
* **Glucose Monitor**,
* **Proximity Monitor**. 

### Device Firmware Update

The **Device Firmware Update (DFU)** profile allows you to update the application, bootloader and/or the Soft Device image over-the-air (OTA). It is compatible with Nordic Semiconductor nRF5x devices that have the S-Series SoftDevice and bootloader enabled. From version 1.5 onward, the nRF Toolbox has allowed to send the required init packet. More information about the init packet may be found here: [init packet handling](https://github.com/NordicSemiconductor/nRF-Master-Control-Panel/tree/master/init%20packet%20handling).

The nRF Toolbox 3.0 is using the DFULibrary framework, available here: [IOS-DFU-Library](https://github.com/NordicSemiconductor/IOS-DFU-Library). The library is required to compile the project. Please, follow the steps in this repository to add it to the project.

The DFU has the following features:
- Scans for devices that are in DFU mode.
- Connects to devices in DFU mode and uploads the selected firmware (Softdevice, Bootloader and/or application).
- Allows HEX or BIN file upload through your phone or tablet.
- Allows to update a Softdevice and/or bootloader and application from ZIP automatically.
- Pause, resume, and cancel file uploads.
- Includes pre-installed examples that consist of the Bluetooth Smart heart rate service and running speed and cadence service.

### Note
- iOS 8.0 and above is required.
- iPhone 4S or newer is required.
- iPad 3 or newer is required.
- Compatible with nRF5x devices with S-Series Softdevice and DFU Bootloader flashed.
- nRF51 and nRF52 Development kits can be ordered from http://www.nordicsemi.com/eng/Buy-Online.
- The SDK and SoftDevices are available online at http://developer.nordicsemi.com.
