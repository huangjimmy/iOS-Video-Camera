//
//  DJIIntelligentHotpointMission.h
//  SDKSharedLib
//
//  Created by DJI on 2018/12/13.
//  Copyright © 2018年 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import "DJIIntelligentHotpointMissionTypes.h"
#import "DJIMission.h"

NS_ASSUME_NONNULL_BEGIN

@class DJIIntelligentHotpointMission;


/**
 *  This class represents an Intelligent Hotpoint mission. In an Intelligent
 *  Hotpoint mission, the aircraft will  repeatedly fly circles of a constant radius
 *  around a specified point called a Hotpoint. The user can control  the aircraft
 *  to fly around the Hotpoint with a specific radius and altitude. During
 *  execution, the user can  also use the physical remote controller to modify its
 *  radius and speed. It is only supported by Mavic 2 Zoom and Mavic 2 Pro.
 */
@interface DJIIntelligentHotpointMission : DJIMission


/**
 *  Checks if the configuration for mission is valid before calling
 *  `startMission:withCompletion` of `DJIIntelligentHotpointMissionOperator`.
 *  
 *  @return Error found when checking parameters of the waypoint. `nil` if all the parameters are valid.
 */
- (nullable NSError *)checkParameters;


/**
 *  Sets the coordinate of the hotpoint.
 */
@property(nonatomic, assign) CLLocationCoordinate2D hotpoint;

@end

NS_ASSUME_NONNULL_END
