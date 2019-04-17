//
//  PDInspectorDomain.h
//  PonyDebuggerDerivedSources
//
//  Generated on 7/10/15
//
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import "PDObject.h"
#import "PDDebugger.h"
#import "PDDynamicDebuggerDomain.h"

@class PDRuntimeRemoteObject;

@protocol PDInspectorCommandDelegate;

@interface PDInspectorDomain : PDDynamicDebuggerDomain 

@property (nonatomic, assign) id <PDInspectorCommandDelegate, PDCommandDelegate> delegate;

// Events
- (void)evaluateForTestInFrontendWithTestCallId:(NSNumber *)testCallId script:(NSString *)script;
- (void)inspectWithObject:(PDRuntimeRemoteObject *)object hints:(NSDictionary *)hints;

// Fired when remote debugging connection is about to be terminated. Contains detach reason.
// Param reason: The reason why connection has been terminated.
- (void)detachedWithReason:(NSString *)reason;

// Fired when debugging target has crashed
- (void)targetCrashed;

@end

@protocol PDInspectorCommandDelegate <PDCommandDelegate>
@optional

/// Enables inspector domain notifications.
- (void)domain:(PDInspectorDomain *)domain enableWithCallback:(void (^)(id error))callback;

/// Disables inspector domain notifications.
- (void)domain:(PDInspectorDomain *)domain disableWithCallback:(void (^)(id error))callback;

@end

@interface PDDebugger (PDInspectorDomain)

@property (nonatomic, readonly, strong) PDInspectorDomain *inspectorDomain;

@end
