//
//  DJIRTKNetworkServiceSettings.h
//  DJISDK
//
//  Copyright © 2018 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Settings for the network service that provides RTK reference station
 *  information.
 */
@interface DJIRTKNetworkServiceSettings : NSObject<NSCopying, NSMutableCopying>


/**
 *  The IP address or the domain name of the server that provides RTK network
 *  services.
 */
@property (nonatomic, readonly) NSString *serverAddress;

/**
 *  The port number that SDK should connect to.
 */
@property (nonatomic, readonly) int port;

/**
 *  User name to access the network service.
 */
@property (nonatomic, readonly) NSString *userName;

/**
 *  Password to access the network service.
 */
@property (nonatomic, readonly) NSString *password;

/**
 *  Mountpoint of the network service, which is a source ID for every streamed
 *  NtripSource.
 */
@property (nonatomic, readonly) NSString *mountpoint;

@end


/**
 *  Settings for the network service that provides RTK reference station
 *  information. This is  the mutable version of `DJIRTKNetworkServiceSettings`.
 */
@interface DJIMutableRTKNetworkServiceSettings : DJIRTKNetworkServiceSettings


/**
 *  The IP address or the domain name of the server that provides RTK network
 *  services.
 */
@property (nonatomic, readwrite) NSString *serverAddress;


/**
 *  The port number that SDK should connect to.
 */
@property (nonatomic, readwrite) int port;

/**
 *  User name to access the network service.
 */
@property (nonatomic, readwrite) NSString *userName;

/**
 *  Password to access the network service.
 */
@property (nonatomic, readwrite) NSString *password;

/**
 *  Mountpoint of the network service, which is a source ID for every streamed
 *  NtripSource.
 */
@property (nonatomic, readwrite) NSString *mountpoint;

@end
