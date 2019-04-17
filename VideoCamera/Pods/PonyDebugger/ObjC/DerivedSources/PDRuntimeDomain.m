//
//  PDRuntimeDomain.m
//  PonyDebuggerDerivedSources
//
//  Generated on 7/10/15
//
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import "PDObject.h"
#import "PDRuntimeDomain.h"
#import "PDObject.h"
#import "PDRuntimeTypes.h"
#import <UIKit/UIKit.h>
#import "PDDebuggerTypes.h"


@interface PDRuntimeDomain ()
//Commands

@end

@implementation PDRuntimeDomain

@dynamic delegate;

+ (NSString *)domainName;
{
    return @"Runtime";
}

// Events

// Issued when new execution context is created.
- (void)executionContextCreatedWithContext:(PDRuntimeExecutionContextDescription *)context;
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:1];

    if (context != nil) {
        [params setObject:[context PD_JSONObject] forKey:@"context"];
    }
    
    [self.debuggingServer sendEventWithName:@"Runtime.executionContextCreated" parameters:params];
}

// Issued when execution context is destroyed.
- (void)executionContextDestroyedWithExecutionContextId:(NSNumber *)executionContextId;
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:1];

    if (executionContextId != nil) {
        [params setObject:[executionContextId PD_JSONObject] forKey:@"executionContextId"];
    }
    
    [self.debuggingServer sendEventWithName:@"Runtime.executionContextDestroyed" parameters:params];
}

// Issued when all executionContexts were cleared in browser
- (void)executionContextsCleared;
{
    [self.debuggingServer sendEventWithName:@"Runtime.executionContextsCleared" parameters:nil];
}



- (void)handleMethodWithName:(NSString *)methodName parameters:(NSDictionary *)params responseCallback:(PDResponseCallback)responseCallback;
{
    if ([methodName isEqualToString:@"enable"]) {
        responseCallback(nil, nil);
        PDRuntimeExecutionContextDescription *context = [[PDRuntimeExecutionContextDescription alloc] init];
        context.identifier = @(1);
//        context.isPageContext = @(NO);
        context.name = [NSString stringWithFormat:@"%@ at %@", [[NSBundle mainBundle] bundleIdentifier], [UIDevice currentDevice].name];
        context.frameId = @"1";
        NSMutableDictionary *contextDict = [[context PD_JSONObject] mutableCopy];
        contextDict[@"origin"] = @"http://localhost/";
        contextDict[@"isDefault"] = @(1);
        [self.debuggingServer sendEventWithName:@"Runtime.executionContextCreated" parameters:@{@"context":contextDict, @"frameId":@(1)}];
        responseCallback(nil, nil);
        return;
    }
    else if ([methodName isEqualToString:@"run"]) {
        responseCallback(nil, nil);
        return;
    }
    else if ([methodName isEqualToString:@"evaluate"] && [self.delegate respondsToSelector:@selector(domain:evaluateWithExpression:objectGroup:includeCommandLineAPI:doNotPauseOnExceptionsAndMuteConsole:contextId:returnByValue:generatePreview:callback:)]) {
        [self.delegate domain:self evaluateWithExpression:[params objectForKey:@"expression"] objectGroup:[params objectForKey:@"objectGroup"] includeCommandLineAPI:[params objectForKey:@"includeCommandLineAPI"] doNotPauseOnExceptionsAndMuteConsole:[params objectForKey:@"doNotPauseOnExceptionsAndMuteConsole"] contextId:[params objectForKey:@"contextId"] returnByValue:[params objectForKey:@"returnByValue"] generatePreview:[params objectForKey:@"generatePreview"] callback:^(PDRuntimeRemoteObject *result, NSNumber *wasThrown, PDDebuggerExceptionDetails *exceptionDetails, id error) {
            NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:3];

            if (result != nil) {
                [params setObject:result forKey:@"result"];
            }
            if (wasThrown != nil) {
                [params setObject:wasThrown forKey:@"wasThrown"];
            }
            if (exceptionDetails != nil) {
                [params setObject:exceptionDetails forKey:@"exceptionDetails"];
            }

            responseCallback(params, error);
        }];
    } else if ([methodName isEqualToString:@"callFunctionOn"] && [self.delegate respondsToSelector:@selector(domain:callFunctionOnWithObjectId:functionDeclaration:arguments:doNotPauseOnExceptionsAndMuteConsole:returnByValue:generatePreview:callback:)]) {
        [self.delegate domain:self callFunctionOnWithObjectId:[params objectForKey:@"objectId"] functionDeclaration:[params objectForKey:@"functionDeclaration"] arguments:[params objectForKey:@"arguments"] doNotPauseOnExceptionsAndMuteConsole:[params objectForKey:@"doNotPauseOnExceptionsAndMuteConsole"] returnByValue:[params objectForKey:@"returnByValue"] generatePreview:[params objectForKey:@"generatePreview"] callback:^(PDRuntimeRemoteObject *result, NSNumber *wasThrown, id error) {
            NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:2];

            if (result != nil) {
                [params setObject:result forKey:@"result"];
            }
            if (wasThrown != nil) {
                [params setObject:wasThrown forKey:@"wasThrown"];
            }

            responseCallback(params, error);
        }];
    } else if ([methodName isEqualToString:@"getProperties"] && [self.delegate respondsToSelector:@selector(domain:getPropertiesWithObjectId:ownProperties:accessorPropertiesOnly:generatePreview:callback:)]) {
        [self.delegate domain:self getPropertiesWithObjectId:[params objectForKey:@"objectId"] ownProperties:[params objectForKey:@"ownProperties"] accessorPropertiesOnly:[params objectForKey:@"accessorPropertiesOnly"] generatePreview:[params objectForKey:@"generatePreview"] callback:^(NSArray *result, NSArray *internalProperties, PDDebuggerExceptionDetails *exceptionDetails, id error) {
            NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:3];

            if (result != nil) {
                [params setObject:result forKey:@"result"];
            }
            if (internalProperties != nil) {
                [params setObject:internalProperties forKey:@"internalProperties"];
            }
            if (exceptionDetails != nil) {
                [params setObject:exceptionDetails forKey:@"exceptionDetails"];
            }

            responseCallback(params, error);
        }];
    } else if ([methodName isEqualToString:@"releaseObject"] && [self.delegate respondsToSelector:@selector(domain:releaseObjectWithObjectId:callback:)]) {
        [self.delegate domain:self releaseObjectWithObjectId:[params objectForKey:@"objectId"] callback:^(id error) {
            responseCallback(nil, error);
        }];
    } else if ([methodName isEqualToString:@"releaseObjectGroup"] && [self.delegate respondsToSelector:@selector(domain:releaseObjectGroupWithObjectGroup:callback:)]) {
        [self.delegate domain:self releaseObjectGroupWithObjectGroup:[params objectForKey:@"objectGroup"] callback:^(id error) {
            responseCallback(nil, error);
        }];
    } else if ([methodName isEqualToString:@"run"] && [self.delegate respondsToSelector:@selector(domain:runWithCallback:)]) {
        [self.delegate domain:self runWithCallback:^(id error) {
            responseCallback(nil, error);
        }];
    } else if ([methodName isEqualToString:@"enable"] && [self.delegate respondsToSelector:@selector(domain:enableWithCallback:)]) {
        [self.delegate domain:self enableWithCallback:^(id error) {
            responseCallback(nil, error);
        }];
    } else if ([methodName isEqualToString:@"disable"] && [self.delegate respondsToSelector:@selector(domain:disableWithCallback:)]) {
        [self.delegate domain:self disableWithCallback:^(id error) {
            responseCallback(nil, error);
        }];
    } else if ([methodName isEqualToString:@"isRunRequired"] && [self.delegate respondsToSelector:@selector(domain:isRunRequiredWithCallback:)]) {
        [self.delegate domain:self isRunRequiredWithCallback:^(NSNumber *result, id error) {
            NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:1];

            if (result != nil) {
                [params setObject:result forKey:@"result"];
            }

            responseCallback(params, error);
        }];
    } else if ([methodName isEqualToString:@"setCustomObjectFormatterEnabled"] && [self.delegate respondsToSelector:@selector(domain:setCustomObjectFormatterEnabledWithEnabled:callback:)]) {
        [self.delegate domain:self setCustomObjectFormatterEnabledWithEnabled:[params objectForKey:@"enabled"] callback:^(id error) {
            responseCallback(nil, error);
        }];
    } else {
        [super handleMethodWithName:methodName parameters:params responseCallback:responseCallback];
    }
}

@end


@implementation PDDebugger (PDRuntimeDomain)

- (PDRuntimeDomain *)runtimeDomain;
{
    return [self domainForName:@"Runtime"];
}

@end
