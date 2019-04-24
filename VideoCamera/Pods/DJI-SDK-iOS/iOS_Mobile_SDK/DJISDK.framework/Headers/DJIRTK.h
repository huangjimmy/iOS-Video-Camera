//
//  DJIRTK.h
//  DJISDK
//
//  Copyright © 2017, DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <DJISDK/DJIBaseProduct.h>
#import <DJISDK/DJIRTKServcieBaseTypes.h>
NS_ASSUME_NONNULL_BEGIN

@class DJIRTK;
@class DJIRTKState;
@class DJIRTKBaseStationBatteryState;

/**
 *  This enum defines the positioning solution currently being used.
 */
typedef NS_ENUM (uint8_t, DJIRTKPositioningSolution){


    /**
     *  No positioning solution. This can be caused by an insufficient number of
     *  satellites in view, insufficient time to lock onto the satellites, or a  loss in
     *  communication link between the mobile station and base station.
     */
    DJIRTKPositioningSolutionNone,


    /**
     *  RTK point positioning.
     */
    DJIRTKPositioningSolutionSinglePoint,


    /**
     *  Float solution positioning.
     */
    DJIRTKPositioningSolutionFloat,


    /**
     *  Fixed-point solution positioning (most accurate).
     */
    DJIRTKPositioningSolutionFixedPoint,
    

    /**
     *  Unknown.
     */
    DJIRTKPositioningSolutionUnknown,
};


/**
 *  This enum defines the data source (either GPS or RTK) of a recorded location,
 *  e.g. home point. Only support by Phantom 4 RTK.
 */
typedef NS_ENUM (uint8_t, DJIRTKDataSource){
    

    /**
     *  The location coordinate is from GPS.
     */
    DJIRTKDataSourceGPS,
    

    /**
     *  The location coordinate is from RTK.
     */
    DJIRTKDataSourceRTK,
    

    /**
     *  Data source is unknown.
     */
    DJIRTKDataSourceUnknown = 0xFF,
    
};

/**
 *  This protocol provides a delegate method to update the RTK state.
 */
@protocol DJIRTKDelegate <NSObject>

@optional


/**
 *  Callback function that updates the RTK state data.
 *  
 *  @param rtk Instance of the RTK.
 *  @param state Current state of the RTK.
 */
- (void)rtk:(DJIRTK *_Nonnull)rtk didUpdateState:(DJIRTKState *_Nonnull)state;


/**
 *  Callback function that updates the RTK base station battery state. Only
 *  Supported by Phantom 4 RTK.
 *  
 *  @param rtk Instance of the RTK.
 *  @param state Base station battery State.
 */
- (void)rtk:(DJIRTK *_Nonnull)rtk didUpdateBaseStationBatteryState:(DJIRTKBaseStationBatteryState *)state;


/**
 *  Callback function that updates the RTK reference station source.
 *  
 *  @param rtk Instance of the RTK.
 *  @param source Reference station source.
 */
- (void)rtk:(DJIRTK *_Nonnull)rtk didUpdateReferenceStationSource:(DJIRTKReferenceStationSource)source;

@end


/**
 *  Single RTK receiver information. Each receiver is connected to a single antenna.
 */
@interface DJIRTKReceiverInfo : NSObject


/**
 *  `YES` if constellation is supported. The European and American versions of RTK
 *  support GPS and GLONASS, while the Asia Pacific version supports GPS and BeiDou.
 */
@property(nonatomic, readonly) BOOL isConstellationSupported;


/**
 *  Valid satellite count for this receiver.
 */
@property(nonatomic, readonly) NSInteger satelliteCount;

@end


/**
 *  Standard deviation of location accuracy in meters. Only Supported by Phantom 4
 *  RTK.
 */
@interface DJILocationStandardDeviation : NSObject


/**
 *  Latitude standard deviation in meters.
 */
@property (nonatomic, readonly) float latitude;


/**
 *  Longitude standard deviation in meters.
 */
@property (nonatomic, readonly) float longtitude;


/**
 *  Altitude standard deviation in meters.
 */
@property (nonatomic, readonly) float altitude;

@end


/**
 *  This class holds the state of the RTK system, including position, positioning
 *  solution, and receiver information.  Receiver 1 is used for positioning.
 *  Receiver 2 is used for orienteering.
 */
@interface DJIRTKState : NSObject


/**
 *  Gets RTK errors, if any. Returns `nil` when RTK is normal.
 */
@property(nonatomic, readonly) NSError *_Nullable error;


/**
 *  The positioning solution describes the method used to determine positioning. The
 *  solutions vary in accuracy, from `DJIRTKPositioningSolutionNone` (no
 *  positioning) to `DJIRTKPositioningSolutionFixedPoint`.
 */
@property(nonatomic, readonly) DJIRTKPositioningSolution positioningSolution;


/**
 *  Mobile station (aircraft) receiver 1 GPS info.
 */
@property(nonatomic, readonly) DJIRTKReceiverInfo *_Nonnull mobileStationReceiver1GPSInfo;


/**
 *  Mobile station (aircraft) receiver 1 BeiDou info.
 */
@property(nonatomic, readonly) DJIRTKReceiverInfo *_Nonnull mobileStationReceiver1BeiDouInfo;


/**
 *  Mobile station (aircraft) receiver 1 GLONASS info.
 */
@property(nonatomic, readonly) DJIRTKReceiverInfo *_Nonnull mobileStationReceiver1GLONASSInfo;


/**
 *  Mobile station (aircraft) receiver 1 Galileo info. Only Supported by Phantom 4
 *  RTK.
 */
@property(nonatomic, readonly) DJIRTKReceiverInfo *_Nonnull mobileStationReceiver1GalileoInfo;


/**
 *  Mobile station (aircraft) receiver 2 GPS info.
 */
@property(nonatomic, readonly) DJIRTKReceiverInfo *_Nonnull mobileStationReceiver2GPSInfo;


/**
 *  Mobile station (aircraft) receiver 2 BeiDou info.
 */
@property(nonatomic, readonly) DJIRTKReceiverInfo *_Nonnull mobileStationReceiver2BeiDouInfo;


/**
 *  Mobile station (aircraft) receiver 2 GLONASS info.
 */
@property(nonatomic, readonly) DJIRTKReceiverInfo *_Nonnull mobileStationReceiver2GLONASSInfo;


/**
 *  Mobile station (aircraft) receiver 2 Galileo info. Only Supported by Phantom 4
 *  RTK.
 */
@property(nonatomic, readonly) DJIRTKReceiverInfo *_Nonnull mobileStationReceiver2GalileoInfo;


/**
 *  Base station receiver GPS info.
 */
@property(nonatomic, readonly) DJIRTKReceiverInfo *_Nonnull baseStationReceiverGPSInfo;


/**
 *  Base station receiver BeiDou info.
 */
@property(nonatomic, readonly) DJIRTKReceiverInfo *_Nonnull baseStationReceiverBeiDouInfo;


/**
 *  Base station receiver GLONASS info.
 */
@property(nonatomic, readonly) DJIRTKReceiverInfo *_Nonnull baseStationReceiverGLONASSInfo;


/**
 *  Base station receiver Galileo info. Only Supported by Phantom 4 RTK.
 */
@property(nonatomic, readonly) DJIRTKReceiverInfo *_Nonnull baseStationReceiverGalileoInfo;


/**
 *  Always indicate RTK location data. Location information of the mobile station's
 *  receiver 1 antenna. This location  information is relative to the base station's
 *  location and is in degrees when `positioningSolution`  is
 *  `DJIRTKPositioningSolutionFixedPoint`.
 */
@property(nonatomic, readonly) CLLocationCoordinate2D mobileStationLocation;


/**
 *  Always indicate RTK altitude data. Altitude in meters of the mobile station's
 *  receiver 1 antenna relative to sea level.
 */
@property(nonatomic, readonly) float mobileStationAltitude;


/**
 *  Standard deviation of location accuracy in meters. Returns `nil` when the
 *  aircraft receives no signal.  Only Supported by Phantom 4 RTK.
 */
@property(nonatomic, readonly) DJILocationStandardDeviation *mobileStationStandardDeviation;


/**
 *  The fusion location of the mobile station (in degrees). It is the combination of
 *  GPS and RTK. The flight controller uses this location for navigation (e.g.
 *  waypoint mission) when RTK is available.
 */
@property(nonatomic, readonly) CLLocationCoordinate2D mobileStationFusionLocation;


/**
 *  The fusion altitude of the mobile station. The flight controller fuses the data
 *  from GPS, RTK and the barometer.  The flight controller uses this altitude for
 *  navigation (e.g. waypoint mission) when RTK is available.
 */
@property(nonatomic, readonly) float mobileStationFusionAltitude;


/**
 *  The fusion heading of the mobile station. It is the combination of RTK and the
 *  compass. The flight controller uses this heading for navigation (e.g. waypoint
 *  mission) when RTK is available.
 */
@property(nonatomic, readonly) float mobileStationFusionHeading;


/**
 *  Base station's location coordinates, in degrees.
 */
@property(nonatomic, readonly) CLLocationCoordinate2D baseStationLocation;


/**
 *  Altitude of the base station above sea level, in meters.
 */
@property(nonatomic, readonly) float baseStationAltitude;


/**
 *  Heading relative to True North as defined by the vector formed from Antenna 2 to
 *  Antenna 1 on the mobile station. Unit is degrees.
 */
@property(nonatomic, readonly) float heading;


/**
 *  `YES` if heading value is valid. Heading is invalid when a satellite fix hasn't
 *  been obtained.
 */
@property(nonatomic, readonly) BOOL isHeadingValid;


/**
 *  Whether the RTK is being used.
 */
@property(nonatomic, readonly) BOOL isRTKBeingUsed;


/**
 *  Distance to home point data source. Only Supported by Phantom 4 RTK.
 */
@property(nonatomic, readonly) DJIRTKDataSource distanceToHomePointDataSource;


/**
 *  `YES` if the altitude is recorded by the flight controller when the aircraft
 *  takes off. Only Supported by Phantom 4 RTK.
 */
@property(nonatomic, readonly) BOOL isTakeoffAltitudeRecorded;


/**
 *  Home point data source. Only Supported by Phantom 4 RTK.
 */
@property(nonatomic, readonly) DJIRTKDataSource homePointDataSource;


/**
 *  Gps or RTK satellite count. Only Supported by Phantom 4 RTK.
 */
@property(nonatomic, readonly) int satelliteCount;


/**
 *  Home point location. Only Supported by Phantom 4 RTK.
 */
@property(nonatomic, readonly) CLLocationCoordinate2D homePointLocation;


/**
 *  Takeoff altitude. Only Supported by Phantom 4 RTK.
 */
@property(nonatomic, readonly) float takeoffAltitude;


/**
 *  Distance to home point. Only Supported by Phantom 4 RTK.
 */
@property(nonatomic, readonly) float distanceToHomePoint;

@end


/**
 *  Real Time Kinematic
 */
@interface DJIRTK : NSObject


/**
 *  DJI RTK delegate.
 */
@property(nonatomic, weak) id<DJIRTKDelegate> delegate;


/**
 *  `YES` if RTK is connected to the aircraft.
 */
@property(nonatomic, readonly) BOOL isConnected;


/**
 *  Enables RTK positioning. Disable RTK when in poor signal environments, where
 *  incorrect positioning information might make controlling the aircraft difficult.
 *  Can only be set when the motors are off.
 *  
 *  @param enabled `YES` to enable RTK positioning.
 *  @param completion Completion block that receives setter result.
 */
- (void)setRTKEnabled:(BOOL)enabled withCompletion:(DJICompletionBlock)completion;


/**
 *  Determines if RTK is enabled. Phantom 4 RTK has different behavior from the
 *  other products that supports RTK:
 *   - For aircrafts except Phantom 4 RTK,  disabling RTK will stop RTK from pushing
 *  valid position.
 *   - For Phantom  4 RTK, RTK will continue to push latest RTK coordinate if there
 *  is strong  satellite signal after disabling RTK. However, the flight controller
 *  will  not use the RTK coordinate for navigation.
 *  
 *  @param enabled `YES` if RTK is enabled.
 *  @param error Error occurs if there is any.
 *  @param completion The completion block that receives the result.
 */
- (void)getRTKEnabledWithCompletion:(void (^)(BOOL enabled, NSError *_Nullable error))completion;


/**
 *  Sets the reference station source that provides real-time corrections for the
 *  RTK air system. It is only supported by Phantom 4 RTK. For Matrice 210 RTK and
 *  Matrice 600 series, the reference station is always the physical base station.
 *  
 *  @param source Reference station source to set.
 *  @param completion The completion block that receives the result.
 */
- (void)setReferenceStationSource:(DJIRTKReferenceStationSource)source withCompletion:(DJICompletionBlock)completion;

/*********************************************************************************/
#pragma mark Base Station
/*********************************************************************************/


/**
 *  Gets the referencing position manually configured to the base station. When a
 *  user can get a more accurate position (coordinate with less absolute error) of
 *  the base station by using external tools, the accurate position can be set to
 *  the base station to improve the accuracy of the aircraft location. If the offset
 *  between the referencing position and the location detected by the base station
 *  is  larger than 5 meters, the base station will ignore the referencing position.
 *  It is  only supported by Phantom 4 RTK.
 *  
 *  @param location The referencing position of the base station.
 *  @param error Error if there is any.
 *  @param completion Completion block that receives the execution result.
 */
- (void)getRTKBaseStationReferencingPositionWithCompletion:(void (^_Nonnull)(CLLocation *_Nullable location, NSError *_Nullable error))completion;


/**
 *  Sets the referencing position of the base station to improve the accuracy. When
 *  a user  can get a more accurate position (coordinate with less absolute error)
 *  of the base station  by using external tools, the accurate position can be set
 *  to the base station to improve  the accuracy of the aircraft location. If the
 *  offset between the referencing position and  the location detected by the base
 *  station is larger than 5 meters, the base station will  ignore the referencing
 *  position. Also, the location to be set should be within a 50 meters  radius of
 *  current base station's location. It is only supported by Phantom 4 RTK.
 *  
 *  @param location The referencing position of the base station.
 *  @param completion Completion block that receives the execution result.
 */
- (void)setRTKBaseStationReferencingPosition:(CLLocation *)location withCompletion:(DJICompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
