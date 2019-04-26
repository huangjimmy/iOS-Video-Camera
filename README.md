# iOS-Video-Camera

Video Camera is an iOS video camera for vloggers with DJI Osmo Mobile 2 gimbal support. It supports manual control of exposure, shutter, ISO , focus and external bluetooth mic as audio input, which is not available in native iOS camera.

This app should also support DJI Osmo Mobile gimbal but it is not tested.

The main objective of this project is to build an opensource version of Filmic Pro iOS version.

## Features

### Manual adjustment of Shutter/ISO/Focus/Zoom

[![Manual adjustment of exposure](https://huangjimmy.github.io/camera_exposure.gif)]

[![Manual adjustment of zoom](https://huangjimmy.github.io/camera_osmo_zoom.gif)]

### Osmo Mobile 2 handheld gimbal support

If you will use iOS Video Camera with DJI Osmo Mobile or Osmo Mobile 2, Video Camera will turn off video stabilization when gimbal is connected via Bluetooth.

[![Osmo Mobile 2 Gimbal support](https://huangjimmy.github.io/camera_osmo_mobile.gif)]

## Features yet to implmented

* Zhiyun Smooth4 gimbal support
* Video Library and "Save to camera roll". Currently all videos shooted are saved in Document directory inside App's sandbox.
* S-Log color mode
* Object tracking

## License

GPLv3

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.

ALBatteryView (https://github.com/andrealufino/ALBatteryView) used in this project is distributed under MIT license.
ALQuickFrame (https://github.com/andrealufino/ALQuickFrame) is distributed under unspecified license.

This does not apply to the pods included in the project either which have their own license

This app uses 

* DeviceGuru (https://github.com/InderKumarRathore/DeviceGuru) a simple lib (Swift) to know the exact type of the device
* DJI-SDK-iOS (https://github.com/dji-sdk/Mobile-SDK-iOS) The DJI Mobile SDK enables this app to response to DJI gimbal
* SVProgressHUD (https://github.com/SVProgressHUD/SVProgressHUD) a clean and easy-to-use HUD meant to display the progress of an ongoing task on iOS and tvOS.