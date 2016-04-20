# iOS DFU Library

## Changelog

  - **0.1.5**: Improved readme
  - **0.1.4**: Removed unnecessary public headears from PodSpec
  - **0.1.3**: Removed extraneous IntelHextBin module as it's no longer necessary
  - **0.1.2**: Added Pod name that caused a missing reference issue and other minor bugfixes
  - **0.1.1**: Bugfix: Release/Debug configurations had a missing reference
  - **0.1.0**: Initial Pod implementation

## Usage

---

#### Method 1: Via Cocoapods (Recommended method)

  - Open up a terminal window and **cd** to your project's root directory
  - Create a **Podfile** with the following content

        use_frameworks!
            pod 'iOSDFULibrary'
        end

  - Install dependencies

        pod install

  - Open the newly created `.xcworkspace` and begin working on your project.

---

#### Method 2: Building from source
 - Create a new blank XCode workspace `/path/to/workspace` and open it
 - In Finder, drag your main project's `xcodeproject` file from `/path/to/myProject` into the new workspace
 - Clone the repository our other repository into `/path/to/dfuLibrary`

        cd /path/to/dfuLibrary && git clone git@github.com:NordicSemiconductor/IOS-DFU-Library.git

 - In Finder, Drag the librarie's `xcodeproject` file into your workspace
 - Begin working on your project from within the workspace.

---

### Device Firmware Update (DFU)

The nRF5x Series chips are flash-based SoCs, and as such they represent the most flexible solution available. A key feature of the nRF5x Series and their associated software architecture
and S-Series SoftDevices is the possibility for Over-The-Air Device Firmware Upgrade (OTA-DFU). See Figure 1. OTA-DFU allows firmware upgrades to be issued and downloaded to products 
in the field via the cloud and so enables OEMs to fix bugs and introduce new features to products that are already out on the market. 
This brings added security and flexibility to product development when using the nRF5x Series SoCs.

This repository contains a tested library for iOS 8+ platform which may be used to perform Device Firmware Update on the nRF5x device using an iPhone or an iPad.

DFU library has been designed to make it very easy to include these devices into your application. It is compatible with all Bootloader/DFU versions.

[![Alt text for your video](http://img.youtube.com/vi/LdY2m_bZTgE/0.jpg)](http://youtu.be/LdY2m_bZTgE)

### Documentation

See the [documentation](documentation) for more information.

### Requirements

The library is compatible with nRF51 and nRF52 devices with S-Series Soft Device and the DFU Bootloader flashed on. 

### DFU History

* **SDK 4.3.0** - First version of DFU over Bluetooth Smart. DFU supports Application update.
* **SDK 6.0.0** - DFU Bootloader supports Soft Device and Bootloader update. As the updated Bootloader may be dependent on the new Soft Device, those two may be sent and installed together.
* **SDK 6.1.0** - Buttonless update support for non-bonded devices.
* **SDK 7.0.0** - The extended init packet is required. The init packet contains additional validation information: device type and revision, application version, compatible Soft Devices and the firmware CRC.
* **SDK 8.0.0** - The bond information may be preserved after an application update. The new application, when first started, will send the Service Change indication to the phone to refresh the services.
- Buttonless update support for bonded devices - sharing the LTK between an app and the bootloader.

Check platform folders for mode details about compatibility for each library.

### Resources

- [DFU Introduction](http://infocenter.nordicsemi.com/topic/com.nordic.infocenter.sdk5.v11.0.0/examples_ble_dfu.html?cp=4_0_0_4_2_1 "BLE Bootloader/DFU")
- [How to create init packet](https://github.com/NordicSemiconductor/nRF-Master-Control-Panel/tree/master/init%20packet%20handling "Init packet handling")
- [nRF51 Development Kit (DK)](http://www.nordicsemi.com/eng/Products/nRF51-DK "nRF51 DK") (compatible with Arduino Uno Revision 3)
- [nRF52 Development Kit (DK)](http://www.nordicsemi.com/eng/Products/Bluetooth-Smart-Bluetooth-low-energy/nRF52-DK "nRF52 DK") (compatible with Arduino Uno Revision 3)
