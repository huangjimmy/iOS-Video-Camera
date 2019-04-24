//
//  DJICompassState.h
//  DJISDK
//
//  Copyright © 2018, DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DJIIMUState.h"


/**
 *  Enum for Compass sensor Status.
 */
typedef NS_ENUM (NSUInteger, DJICompassSensorState) {
	

	/**
	 *  The Compass sensor is disconnected from the flight controller.
	 */
	DJICompassSensorStateDisconnected,
	

	/**
	 *  The Compass sensor is calibrating.
	 */
	DJICompassSensorStateCalibrating,
	

	/**
	 *  The Compass sensor is not in calibrating.
	 */
	DJICompassSensorStateIdle,
	

	/**
	 *  The Compass sensor has a data exception. Calibrate the compass and restart the
	 *  aircraft.  If afterwards the status still exists, you may need to contact DJI
	 *  for further assistance.
	 */
	DJICompassSensorStateDataException,
	

	/**
	 *  The compass sensor super modulus is too samll.
	 */
	DJICompassSensorStateSuperModulusSamll,
	

	/**
	 *  The compass sensor super modulus is too weak.
	 */
	DJICompassSensorStateSuperModulusWeak,
	

	/**
	 *  The compass sensor super modulus is deviate.
	 */
	DJICompassSensorStateSuperModulusDeviate,
	

	/**
	 *  The Compass sensor is calibrating failed.
	 */
	DJICompassSensorStateCalibrationFailed,
	

	/**
	 *  The Compass sensor is inconsistent direction.
	 */
	DJICompassSensorStateInconsistentDirection,
	

	/**
	 *  The IMU sensor's status is unknown.
	 */
	DJICompassSensorStateUnknown = 0xFF,
	
};


/**
 *  The state of the DJICompass.
 */
@interface DJICompassState : NSObject


/**
 *  The Compass's ID. Starts at 0, It is same with IMU state.
 */
@property (nonatomic, readonly) NSUInteger index;


/**
 *  The compass sensor's value.
 */
@property (nonatomic, readonly) float sensorValue;


/**
 *  The compass sensor's state value.
 */
@property (nonatomic, readonly) DJICompassSensorState state;

@end
