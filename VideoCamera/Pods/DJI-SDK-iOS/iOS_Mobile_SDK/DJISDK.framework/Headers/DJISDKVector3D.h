//
//  DJISDKVector3D.h
//  DJISDK
//
//  Copyright © 2017, DJI. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  A cartesian vector in 3D space.
 */
__attribute__((objc_runtime_name("74f47570-7b7b-11e8-bf4d-a860b61add44"))) 
@interface DJISDKVector3D : NSObject


/**
 *  X-value of the cartesian vector.
 */
@property(nonatomic, assign, getter=roll) double x;


/**
 *  Y-value of the cartesian vector.
 */
@property(nonatomic, assign, getter=pitch) double y;


/**
 *  Z-value of the cartesian vector.
 */
@property(nonatomic, assign, getter=yaw) double z;

@end
