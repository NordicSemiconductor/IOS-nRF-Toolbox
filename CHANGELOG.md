# Changelog 

New in V4.5.1:

* DFU Library 4.5.1 - fixed issue with DFU on iOS 13.

New in V4.5.0:

* Migrated to Swift 5
* DFU Library 4.5.0
* Lots of issues fixed
* New Nordic look&feel

New in V4.4.4:

* Improved HomeKit view, allowing user to switch homes, and create a home if none exists.
* Fixed issuew with HomeKit showing permission error as soon as the permission was given.
* Removed automatic home creation in HomeKit view, now user can manually create the home.
* Improved error handling to show the user actual parsed messages from homekit errors instead of showing generic errors.
* Updated DFULibrary to version 4.1.1.
* Improved fieltype selection UI.
* Added an option to allow users to select the DFU scope when flashing distribution packages.

New in V4.4.3:

* Fixed a bug causing DFU errors not to be displayed properly on the DFU screen.
* Added ability to flash SoftDevice + Bootloader Hex files.
* Updated iOSDFULibrary to version 4.1.0.

New in V4.4.2:

* Fixed an issue with glucose monitors context reading that caused a crash or missing data from the reading context.
* iPhone X support.
* iOS11 Support (Large navigation bar).
* Swift 4 migration.
* iOSDFULibrary V4.0.2 updated within app.
* UI improvements for smaller screens, and improvemetns for newer lagers screens.

New in V4.4.1:

* Fixed an issue introduced in V4.4.0 causing the HomeKit accessory service to not be readable.
* Enhanced HomeKit profile view by notifying of any HomeKit related errors instead of logging to console.

New in V4.4.0:

* Adds HomeKit profile, allowing browsing and adding HomeKit accessories.
* Adds Secure DFU Feature for HomeKit accessories, accessible through the HomeKit Profile view.
* Fixed small icon size issues for 3x resolution devices (iPhone 6+/7+).
* Improved UI throughout the app and all the profile views.

New in V4.3.0:

* Adds Experimental Buttonless DFU feature.
* DFU Library version now displayed in the DFU View.
* Minor UI improvements.
* Updated iOSDFULibrary to v3.0.6.

New in v4.1.1:

* Fixed bug with reading IEEE Float values.
* Fixed erratic values in HTS Example view see issue #27.
* Fixed bug causing intermittent failures in scanner view.
* Updated iOSDFULibrary to v2.1.2.

New in v4.1:

* The application is now Fully migrated to Swift 3.0.
* Bugfix: Importing of distribution packets via email no longer crashes.
* Bugfix: Glucose monitor demo no longer crashes/displays incorrect timestamps when the device uses the 12 hour format locale.
* Bugfix: Glucose monitor demo no longer duplicates data on the last row when refresh button is tapped.

New in v4.0:

* The application is fully migrated to Swift 2.2.
* Added **Continuous Glucose Monitor** profile support.
* The Application now uses the Cocoapods version of our DFU Library. See [cocoapods/iOSDFULibrary](https://cocoapods.org/pods/iOSDFULibrary).
* Minor bugfixes in characteristics reading on some profiles.

New in v3.0:

* The application uses DFU Library, instead of having it's own implementation.

New in v2.5:

* Refreshed Look & Feel.
* Better user experience in DFU and UART profiles.
* Bug fixes.