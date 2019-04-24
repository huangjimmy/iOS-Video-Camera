//
//  DJIRTKServcieBaseTypes.h
//  DJISDK
//
//  Copyright © 2018 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/**
 *  All the possible state of `DJIRTKReferenceStationSource`.
 */
typedef NS_ENUM(uint8_t, DJIRTKReferenceStationSource) {

    /**
     *  RTK is using the D-RTK 2 base station as the reference station.
     */
    DJIRTKReferenceStationSourceBaseStation,

    /**
     *  RTK is using third-party network service as the reference station. The network
     *  service should use  NTRIP(Networked Transport of RTCM via  Internet Protocol).
     */
    DJIRTKReferenceStationSourceCustomNetworkService,

    /**
     *  Unknown reference station source.
     */
    DJIRTKReferenceStationSourceUnknown = 0xFF,
};


/**
 *  All the possible state of `DJIRTKNetworkServiceChannelState`.
 */
typedef NS_ENUM(uint8_t, DJIRTKNetworkServiceChannelState) {

    /**
     *  The network service is not started.
     */
    DJIRTKNetworkServiceChannelStateDisabled,

    /**
     *  The network is not reachable from the mobile device.
     */
    DJIRTKNetworkServiceChannelStateNetworkNotReachable,

    /**
     *  The aircraft is not connected.
     */
    DJIRTKNetworkServiceChannelStateAircraftDisconnected,

    /**
     *  SDK cannot login with the provided username and password.  Check `error`.
     */
    DJIRTKNetworkServiceChannelStateLoginFailure,

    /**
     *  The channel from the server to the aircraft is built up. It is ready  for
     *  transmission.
     */
    DJIRTKNetworkServiceChannelStateReady,

    /**
     *  Data is transmitting through the channel.
     */
    DJIRTKNetworkServiceChannelStateTransmitting,

    /**
     *  The channel is disconnected and the server is not reachable now. Check `error`.
     */
    DJIRTKNetworkServiceChannelStateDisconnected,

    /**
     *  Unknown.
     */
    DJIRTKNetworkServiceChannelStateUnknown = 0xFF,
};


/**
 *  The state of network service that provides reference station information.
 */
@interface DJIRTKNetworkServiceState : NSObject<NSCopying>


/**
 *  The state of the channel from the aircraft to the server that provides RTK
 *  network service.
 */
@property (nonatomic, readonly) DJIRTKNetworkServiceChannelState channelState;


/**
 *  The encountered error if any when building up the channel from the aircraft to
 *  the server  that provides RTK network service.
 */
@property (nonatomic, nullable, readonly) NSError *error;

@end


/**
 *  RTK Base Station Current Battery State. Only Supported by Phantom 4 RTK.
 */
@interface DJIRTKBaseStationBatteryState : NSObject


/**
 *  Returns the current RTK base station battery voltage (mV).
 */
@property(nonatomic, readonly) uint32_t voltage;


/**
 *  Returns the real time current draw of the RTK base station battery (mA).
 */
@property(nonatomic, readonly) uint32_t current;


/**
 *  Returns the current RTK base station battery's temperature, in Celsius, with
 *  range [-128, 127] degrees.
 */
@property(nonatomic, readonly) int16_t temperature;



/**
 *  Returns the battery's remaining lifetime as a percentage, with range [0, 100]. A
 *  new battery will be close to 100%.  As a battery experiences charge/discharge
 *  cycles, the value will go down.
 */
@property(nonatomic, readonly) uint8_t capacityPercent;

@end
NS_ASSUME_NONNULL_END
