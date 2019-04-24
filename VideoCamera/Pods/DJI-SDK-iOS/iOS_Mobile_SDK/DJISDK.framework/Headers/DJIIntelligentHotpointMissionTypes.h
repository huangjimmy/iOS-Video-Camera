//
//  DJIIntelligentHotPointMissionTypes.h
//  DJISDK
//
//  Copyright © 2017, DJI. All rights reserved.
//

#import "DJISDKFoundation.h"

#ifndef DJIIntelligentHotPointMissionTypes_h
#define DJIIntelligentHotPointMissionTypes_h


/**
 *  Maximum radius, in meters, of the circular path the aircraft will fly around the
 *  point of interest. Currently 500m.
 */
DJI_API_EXTERN const float DJIIntelligentHotpointMaxRadius;


/**
 *  Minimum radius, in meters, of the circular path the aircraft will fly around the
 *  point of interest.
 */
DJI_API_EXTERN const float DJIIntelligentHotpointMinRadius;


/**
 *  Maximum altitude in meters for an Intelligent Hotpoint mission.
 */
DJI_API_EXTERN const float DJIIntelligentHotpointMaxAltitude;


/**
 *  Minimum altitude in meters for an Intelligent Hotpoint mission.
 */
DJI_API_EXTERN const float DJIIntelligentHotpointMinAltitude;


/**
 *  This enum defines the mission mode.
 */
typedef NS_ENUM(NSInteger, DJIIntelligentHotpointMissionMode) {
    

    /**
     *  This mode means current mission is started by `startMission:withCompletion`.
     */
    DJIIntelligentHotpointMissionModeGPS,
    

    /**
     *  This mode means current mission is started by
     *  `startRecognizeTargetInRect:withCompletion`  and
     *  `acceptConfirmationWithCompletion`. In this mode, you  can
     *  `resetGimbalToCenterWithCompletion` while mission is executing or paused.
     */
    DJIIntelligentHotpointMissionModeVision,
    

    /**
     *  The mission mode is unknown.
     */
    DJIIntelligentHotpointMissionModeUnknown = 0xFF,
};

#endif /* DJIIntelligentHotPointMissionTypes_h */
