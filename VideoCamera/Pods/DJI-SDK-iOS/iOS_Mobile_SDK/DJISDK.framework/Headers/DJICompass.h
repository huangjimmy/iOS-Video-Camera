//
//  DJICompass.h
//  DJISDK
//
//  Copyright © 2015, DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DJISDK/DJIBaseComponent.h>
#import <DJISDK/DJICompassCalibrationState.h>
#import <DJISDK/DJIIMUState.h>

NS_ASSUME_NONNULL_BEGIN

@class DJICompass;
@class DJICompassState;

/**
 *  This protocol provides delegate methods to update the compass's current state.
 */
@protocol DJICompassDelegate <NSObject>

@optional


/**
 *  Called when the compass pushes an compass calibration state update.
 *  
 *  @param compass Instance of the compass for which the calibration state will be updated.
 *  @param state `DJICompassCalibrationState` state value.
 */
- (void)compass:(DJICompass *_Nonnull)compass didUpdateCalibrationState:(DJICompassCalibrationState)state;


/**
 *  Called when the compass pushes an compass sensor state update.
 *  
 *  @param compass Instance of the compass for which the compass sensor state will be updated.
 *  @param state `DJICompassState` state value.
 */
- (void)compass:(DJICompass *_Nonnull)compass didUpdateSensorState:(DJICompassState *)state;

@end


/**
 *  This class provides compass status information and compass calibration methods.
 *  Products with multiple compasses (like the Phantom 4) have their compass state
 *  fused into one compass class for simplicity.
 */
@interface DJICompass : NSObject


/**
 *  Compass delegate.
 */
@property(nonatomic, weak) id<DJICompassDelegate> delegate;


/**
 *  Represents the heading, in degrees. True North is 0 degrees, positive heading is
 *  East of North, and negative  heading is West of North. Heading bounds are [-180,
 *  180].
 */
@property(nonatomic, readonly) double heading;


/**
 *  `YES` if the compass has an error. If `YES`, the compass  needs calibration.
 */
@property(nonatomic, readonly) BOOL hasError;


/**
 *  `YES` if the compass is currently calibrating.
 */
@property(nonatomic, readonly) BOOL isCalibrating;


/**
 *  Shows the calibration status.
 */
@property(nonatomic, readonly) DJICompassCalibrationState calibrationState;


/**
 *  Starts compass calibration. Make sure there are no magnets or metal objects near
 *  the compass.
 *  
 *  @param completion Completion block that receives the execution result.
 */
- (void)startCalibrationWithCompletion:(DJICompletionBlock)completion;


/**
 *  Stops compass calibration.
 *  
 *  @param completion Completion block that receives the execution result.
 */
- (void)stopCalibrationWithCompletion:(DJICompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
