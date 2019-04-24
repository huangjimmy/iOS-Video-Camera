//
//  DJIIntelligentHotpointMissionOperator.h
//  DJISDK
//
//  Copyright © 2017, DJI. All rights reserved.
//


#import "DJISDKFoundation.h"
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "DJIIntelligentHotpointMissionTypes.h"

NS_ASSUME_NONNULL_BEGIN
@class DJIIntelligentHotpointMissionOperator;
@class DJIIntelligentHotpointMission;


/**
 *  The states of the `DJIIntelligentHotpointMissionOperator`.
 */
typedef NS_ENUM(NSInteger, DJIIntelligentHotpointMissionState) {

    /**
     *  The state of the operator is unknown. This is the initial state when the
     *  operator has just been created.
     */
    DJIIntelligentHotpointMissionStateUnknown = -1,
    

    /**
     *  The state of the operator is unknown. This is the initial state when the
     *  operator has just been created.
     */
    DJIIntelligentHotpointMissionStateDisconnected,
    

    /**
     *  The connection between the mobile device and aircraft is recovering. At this
     *  time, the operator is  synchronizing the state from the aircraft.
     */
    DJIIntelligentHotpointMissionStateRecovering,
    

    /**
     *  The connected product does not support Hotpoint mission.
     */
    DJIIntelligentHotpointMissionStateNotSupported,
    

    /**
     *  The operator is not ready to start an Intelligent Hotpoint mission.
     */
    DJIIntelligentHotpointMissionStateNoReady,


    /**
     *  The operator is ready to start an Intelligent Hotpoint mission.
     */
    DJIIntelligentHotpointMissionStateReadyToStart,
    

    /**
     *  The aircraft's Vision system is recognizing the track object. If recognized the
     *  target, the state will change to
     *  `DJIIntelligentHotpointMissionStateWaitingForConfirmation`.
     */
    DJIIntelligentHotpointMissionStateRecognizingTarget,
    

    /**
     *  The aircraft has recognized the target and is waiting for confirmation.
     */
    DJIIntelligentHotpointMissionStateWaitingForConfirmation,
    

    /**
     *  Confirm success and when a tracking mission started, The Vision system will
     *  measure the track object and calculate the surrounding path. Then it will begin
     *  to surround the track target. The state will change  to
     *  `DJIIntelligentHotpointMissionStateExecuting`.
     */
    DJIIntelligentHotpointMissionStateMeasuringTarget,
    

    /**
     *  The execution is started successfully.
     */
    DJIIntelligentHotpointMissionStateExecuting,


    /**
     *  Hotpoint mission is paused successfully. User can call
     *  `resumeMissionWithCompletion` to continue the execution.
     */
    DJIIntelligentHotpointMissionStateExecutionPaused,
};


/**
 *  This class encapsulates all the state changes of the Intelligent Hotpoint
 *  mission operator.
 */
@interface DJIIntelligentHotpointMissionEvent : NSObject


/**
 *  The previous state of the operator.
 */
@property (nonatomic, readonly) DJIIntelligentHotpointMissionState previousState;


/**
 *  The current state of the operator.
 */
@property (nonatomic, readonly) DJIIntelligentHotpointMissionState currentState;


/**
 *  The current mission mode.
 */
@property (nonatomic, readonly) DJIIntelligentHotpointMissionMode missionMode;


/**
 *  A bounding box for the target. The rectangle is normalized to [0,1] where (0,0)
 *  is the top left of  the video preview and (1,1) is the bottom right. When send
 *  target rect to Vision system, it will  recognize the target and push modified
 *  target bounding box. Value is available if  the `currentState`  is
 *  `DJIIntelligentHotpointMissionStateRecognizingTarget`,
 *  `DJIIntelligentHotpointMissionStateWaitingForConfirmation`,
 *  `DJIIntelligentHotpointMissionStateMeasuringTarget`.
 */
@property (nonatomic, readonly) CGRect targetRect;


/**
 *  The current intelligent hotpoint radius in meters of the mission. If there is no
 *  executing mission, it is 0.
 */
@property (nonatomic, readonly) float currentRadius;


/**
 *  The target intelligent hotpoint radius in meters of the mission. Set by user,
 *  and the `currentRadius`  will change to `targetRadius`. If there is no executing
 *  mission, it is 0.
 */
@property (nonatomic, readonly) float targetRadius;


/**
 *  The current intelligent hotpoint altitude in meters of the mission.
 */
@property (nonatomic, readonly) float currentAltitude;


/**
 *  The target intelligent hotpoint altitude in meters of the mission. Setted by
 *  user, and the `currentAltitude`  will change to `targetAltitude`.
 */
@property (nonatomic, readonly) float targetAltitude;


/**
 *  The intelligent hotpoint max angular velocity from current radius. This value
 *  depends on the current situation of the aircraft.
 */
@property (nonatomic, readonly) float maxAngularVelocity;


/**
 *  The current intelligent hotpoint angular velocity from current radius.
 */
@property (nonatomic, readonly) float angularVelocity;


/**
 *  The intelligent hotpoint's coordinate of the mission.
 */
@property (nonatomic, readonly) CLLocationCoordinate2D hotpoint;


/**
 *  The intelligent hotpoint's encountered error if there is any. Otherwise, it is
 *  `nil`.
 */
@property (nonatomic, readonly, nullable) NSError *error;

@end


/**
 *  The Intelligent hotpoint mission operator is the only object that controls, runs
 *  and monitors Intelligent  Hotpoint Missions. It can be accessed from
 *  `DJIMissionControl`. `DJIIntelligentHotpointMissionOperator`  has two ways to
 *  start an Intelligent hotpoint mission: One is to start a
 *  `DJIIntelligentHotpointMission`,  which will repeatedly around a specified point
 *  called hotpoint. The other you will target a rect in your  FPV view, and send it
 *  to Vision system to track, when the state change to
 *  `DJIIntelligentHotpointMissionOperator_WaitingForConfirmation`,  you can
 *  `acceptConfirmationWithCompletion`, then the aircraft will fly around the
 *  object.  When mission executing, it will not need target object, actually track
 *  mode only help to set hotpoint at a target  object.
 *   Now only supported by Mavic 2 Zoom and Mavic 2 Pro.
 */
@interface DJIIntelligentHotpointMissionOperator : NSObject


/**
 *  `YES` if POI mode is enabled. Value is undefined if  the `currentState` is one
 *  of the  following:
 *   - `DJIIntelligentHotpointMissionStateNotSupported`
 *   - `DJIIntelligentHotpointMissionStateDisconnected`
 *   - `DJIIntelligentHotpointMissionStateRecovering`.
 *   Now only  supported by Mavic 2 Zoom and Mavic 2 Pro.
 */
@property (nonatomic, readonly) BOOL isPOIModeEnabled;


/**
 *  Enable POI mode. enabling POI mode is the pre-condition of starting Intelligent
 *  Hotpoint Mission.  Now only supported by Mavic 2 Zoom and Mavic 2 Pro.
 *  
 *  @param completion Completion block that receives the execution result.
 */
- (void)enablePOIModeWithCompletion:(DJICompletionBlock)completion;


/**
 *  Disable POI mode. When POI mode is disabled, you can not starting Intelligent
 *  Hotpoint mission.  Now only supported by Mavic 2 Zoom and Mavic 2 Pro.
 *  
 *  @param completion Completion block that receives the execution result.
 */
- (void)disablePOIModeWithCompletion:(DJICompletionBlock)completion;


/**
 *  The current state of the executing Intelligent Hotpoint mission.
 */
@property (readonly, nonatomic) DJIIntelligentHotpointMissionState currentState;


/**
 *  Block to receive the Intelligent Hotpoint operator event.
 *  
 *  @param event The Intelligent Hotpoint operator event with the state change.
 */
typedef void (^DJIIntelligentHotpointMissionOperatorEventBlock)(DJIIntelligentHotpointMissionEvent *event);


/**
 *  Adds listener to receive all of the Intelligent Hotpoint mission operator
 *  events.
 *  
 *  @param listener Listener that is interested in the Intelligent Hotpoint mission operator.
 *  @param queue The dispatch queue that `block` will be called on.
 *  @param block Block will be called when there is event updated.
 */
- (void)addListenerToEvents:(id)listener
                  withQueue:(nullable dispatch_queue_t)queue
                   andBlock:(DJIIntelligentHotpointMissionOperatorEventBlock)block;


/**
 *  Block to receive the notification that an Intelligent Hotpoint mission is
 *  started successfully.
 */
typedef void (^DJIIntelligentHotpointMissionOperatorSimpleEventBlock)();


/**
 *  Adds listener to receive a notification when an Intelligent Hotpoint mission is
 *  started.
 *  
 *  @param listener Listener that is interested in the start of the Intelligent Hotpoint mission.
 *  @param queue The dispatch queue that `block` will be called on.
 *  @param block Block will be called when a Hotpoint mission is started.
 */
- (void)addListenerToStarted:(id)listener
                   withQueue:(nullable dispatch_queue_t)queue
                    andBlock:(DJIIntelligentHotpointMissionOperatorSimpleEventBlock)block;


/**
 *  Adds listener to receive a notification when an Intelligent Hotpoint mission is
 *  finished.
 *  
 *  @param listener Listener that is interested in the finish of the Intelligent Hotpoint mission.
 *  @param queue The dispatch queue that `block` will be called on.
 *  @param block Block will be called when an Intelligent Hotpoint mission is finished. If the mission is interrupted with an error,  the error will be passed to the block.
 */
- (void)addListenerToFinished:(id)listener
                    withQueue:(nullable dispatch_queue_t)queue
                     andBlock:(DJICompletionBlock)block;


/**
 *  Removes listener. If the listener is listening to events and notifications, then
 *  it will stop listening to  all if called with this method.
 *  
 *  @param listener Listener to be removed.
 */
- (void)removeListener:(id)listener;


/**
 *  Removes listener from listener pool of events.
 *  
 *  @param listener Listener to be removed.
 */
- (void)removeListenerOfEvents:(id)listener;


/**
 *  Removes listener from listener pool of start mission notifications.
 *  
 *  @param listener Listener to be removed.
 */
- (void)removeListenerOfStarted:(id)listener;


/**
 *  Removes listener from listener pool of stop mission notifications.
 *  
 *  @param listener Listener to be removed.
 */
- (void)removeListenerOfFinished:(id)listener;



/**
 *  Remove all listeners from listener pool.
 */
- (void)removeAllListeners;


/**
 *  Starts to execute an Intelligent Hotpoint mission. This only be called when the
 *  `currentState`  is `DJIIntelligentHotpointMissionStateReadyToStart`. After a
 *  mission is started successfully,  the `currentState` will become
 *  `DJIIntelligentHotpointMissionStateExecuting`.  If the mission starts
 *  successful, the aircraft will fly arround the "hotpoint" of the mission. The
 *  current horizontal distance between the aircraft and the hotpoint must  be
 *  [5,500]. The current vertical distance between the aircraft and the relative
 *  takeoff altitude must be [5,500].
 *  
 *  @param mission An object of `DJIIntelligentHotpointMission`.
 *  @param completion Completion block that will be called when the operator succeeds or fails to start the mission. If it fails, an error will be returned.
 */
- (void)startMission:(DJIIntelligentHotpointMission *)mission withCompletion:(DJICompletionBlock)completion;


/**
 *  Send a target rect in video stream to aircraft, the vision system will recognize
 *  the target in the rect. This only be called when  the `currentState` is
 *  `DJIIntelligentHotpointMissionStateReadyToStart`.  After recognize target
 *  success, the `currentState` will become
 *  `DJIIntelligentHotpointMissionStateWaitingForConfirmation`  means recognize the
 *  target successfully or `DJIIntelligentHotpointMissionStateReadyToStart` means
 *  can not recognize the target.
 *  
 *  @param targetRect The tracking target rect in video stream.
 *  @param completion Completion block that will be called when the operator succeeds or fails to start recognize target. If it fails, an error will be returned.
 */
- (void)startRecognizeTargetInRect:(CGRect)targetRect withCompletion:(DJICompletionBlock)completion;


/**
 *  Confirm the recognized target, only be called when the `currentState`  is
 *  `DJIIntelligentHotpointMissionStateWaitingForConfirmation`. If accept
 *  successfully,  the `currentState` will become
 *  `DJIIntelligentHotpointMissionStateMeasuringTarget`,  the aircraft will measure
 *  the the target and calculate surrounding path. Then the aircraft will start
 *  circle around the target on the surrounding path and `currentState`  will become
 *  `DJIIntelligentHotpointMissionStateExecuting`.
 *  
 *  @param completion Completion block that will be called when the operator succeeds or fails. If it fails, an error will be returned.
 */
- (void)acceptConfirmationWithCompletion:(DJICompletionBlock)completion;


/**
 *  Pauses the executing mission. It can only be called when the `currentState` is
 *  `DJIIntelligentHotpointMissionStateExecuting`.  After a mission is paused
 *  successfully, the `currentState` will become
 *  `DJIIntelligentHotpointMissionStateExecutionPaused`.
 *  
 *  @param completion Completion block that will be called when the operator succeeds or fails. If it fails, an error will be returned.
 */
- (void)pauseMissionWithCompletion:(DJICompletionBlock)completion;


/**
 *  Resumes the paused mission. It can only be called when the `currentState`  is
 *  `DJIIntelligentHotpointMissionStateExecutionPaused`. After a mission is resumed
 *  successfully,  the `currentState` will become
 *  `DJIIntelligentHotpointMissionStateExecuting`.
 *  
 *  @param completion Completion block that will be called when the operator succeeds or fails. If it fails, an error will be returned.
 */
- (void)resumeMissionWithCompletion:(DJICompletionBlock)completion;


/**
 *  Stops the executing or paused mission. It can only be called when `currentState`
 *  is one of the following:
 *   - `DJIIntelligentHotpointMissionStateExecuting`
 *   - `DJIIntelligentHotpointMissionStateExecutionPaused`  After a mission is
 *  stopped successfully, `currentState` will become
 *  `DJIIntelligentHotpointMissionStateReadyToStart`.
 *  
 *  @param completion Completion block that will be called when the operator succeeds or fails. If it fails, an error will be returned.
 */
- (void)stopMissionWithCompletion:(DJICompletionBlock)completion;


/**
 *  Sets angular velocity for the executing mission. It can only be called when
 *  `currentState` is one of the following:
 *   - `DJIIntelligentHotpointMissionStateExecuting`
 *   - `DJIIntelligentHotpointMissionStateExecutionPaused`
 *  
 *  @param angularVelocity Angular velocity to set.
 *  @param completion Completion block that will be called when the operator succeeds or fails. If it fails, an error will be returned.
 */
- (void)setAngularVelocity:(float)angularVelocity withCompletion:(DJICompletionBlock)completion;


/**
 *  Sets radius for the executing mission. It can only be called when the
 *  `currentState` is one of the  following:
 *   - `DJIIntelligentHotpointMissionStateExecuting`
 *   - `DJIIntelligentHotpointMissionStateExecutionPaused`
 *  
 *  @param radius Radius to set.
 *  @param completion Completion block that will be called when the operator succeeds or fails. If it fails, an error will be returned.
 */
- (void)setRadius:(float)radius withCompletion:(DJICompletionBlock)completion;


/**
 *  Sets altitude for the executing mission. It can only be called when the
 *  `currentState` is one of the following:
 *   - `DJIIntelligentHotpointMissionStateExecuting`
 *   - `DJIIntelligentHotpointMissionStateExecutionPaused`
 *  
 *  @param altitude altitude to set.
 *  @param completion Completion block that will be called when the operator succeeds or fails. If it fails, an error will be returned.
 */
- (void)setAltitude:(float)altitude withCompletion:(DJICompletionBlock)completion;


/**
 *  Reset gimbal to center for the executing mission, the camera will direct to the
 *  target. It can only be called when the `currentState` is one of the following:
 *   - `DJIIntelligentHotpointMissionStateExecuting`
 *   - `DJIIntelligentHotpointMissionStateExecutionPaused`
 *   This feature is only avaliable in recognize mission.
 *  
 *  @param completion Completion block that will be called when the operator succeeds or fails. If it fails, an error will be returned.
 */
- (void)resetGimbalToCenterWithCompletion:(DJICompletionBlock)completion;

@end
NS_ASSUME_NONNULL_END
