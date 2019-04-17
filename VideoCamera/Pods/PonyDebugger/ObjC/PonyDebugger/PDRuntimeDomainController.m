//
//  PDRuntimeDomainController.m
//  PonyDebugger
//
//  Created by Wen-Hao Lue on 8/7/12.
//
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import "PDRuntimeDomainController.h"
#import "PDRuntimeTypes.h"

#import "NSObject+PDRuntimePropertyDescriptor.h"
#import "NSManagedObject+PDRuntimePropertyDescriptor.h"
#import "NSArray+PDRuntimePropertyDescriptor.h"
#import "NSSet+PDRuntimePropertyDescriptor.h"
#import "NSOrderedSet+PDRuntimePropertyDescriptor.h"
#import "NSDictionary+PDRuntimePropertyDescriptor.h"
#import "ChromeVirtualMachine.h"

@interface PDRuntimeDomainController () <PDRuntimeCommandDelegate>

// Dictionary where key is a unique objectId, and value is a reference of the value.
@property (nonatomic, strong) NSMutableDictionary *objectReferences;

// Values are arrays of object references.
@property (nonatomic, strong) NSMutableDictionary *objectGroups;

+ (NSString *)_generateUUID;

- (void)_releaseObjectID:(NSString *)objectID;
- (void)_releaseObjectGroup:(NSString *)objectGroup;

@end


@implementation PDRuntimeDomainController

@dynamic domain;

@synthesize objectReferences = _objectReferences;
@synthesize objectGroups = _objectGroups;

#pragma mark - Statics

+ (PDRuntimeDomainController *)defaultInstance;
{
    static PDRuntimeDomainController *defaultInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultInstance = [[PDRuntimeDomainController alloc] init];
    });
    
    return defaultInstance;
}

+ (Class)domainClass;
{
    return [PDRuntimeDomain class];
}

+ (NSString *)_generateUUID;
{
	CFUUIDRef UUIDRef = CFUUIDCreate(nil);
    NSString *newGuid = (__bridge_transfer NSString *) CFUUIDCreateString(nil, UUIDRef);
    CFRelease(UUIDRef);
    return newGuid;
}

#pragma mark - Initialization

- (id)init;
{
    if (!(self = [super init])) {
        return nil;
    }
    
    self.objectReferences = [[NSMutableDictionary alloc] init];
    self.objectGroups = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)dealloc;
{
    self.objectReferences = nil;
    self.objectGroups = nil;
}

#pragma mark - PDRuntimeCommandDelegate

- (void)domain:(PDRuntimeDomain *)domain getPropertiesWithObjectId:(NSString *)objectId ownProperties:(NSNumber *)ownProperties accessorPropertiesOnly:(NSNumber *)accessorPropertiesOnly generatePreview:(NSNumber *)generatePreview callback:(void (^)(NSArray *result, NSArray *internalProperties, PDDebuggerExceptionDetails *exceptionDetails, id error))callback;
{
    NSObject *object = [self.objectReferences objectForKey:objectId];
    if (!object) {
        NSString *errorMessage = [NSString stringWithFormat:@"Object with objectID '%@' does not exist.", objectId];
        NSError *error = [NSError errorWithDomain:PDDebuggerErrorDomain code:100 userInfo:[NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey]];
        
        callback(nil, nil, nil, error);
        return;
    }
    
    NSArray *properties = [object PD_propertyDescriptors];
    for (PDRuntimePropertyDescriptor *prop in properties) {
        NSNumber *number = prop.value.value;
        if([number isKindOfClass:[NSNumber class]]){
            if([number  isEqualToNumber:[NSDecimalNumber notANumber]]){
                prop.value.value = [NSNumber numberWithDouble:0];
            }
            else if(isinf([number doubleValue])){
                prop.value.value = [NSNumber numberWithDouble:0];
            }
        }
    }
    callback(properties, nil, nil, nil);
}

- (void)domain:(PDRuntimeDomain *)domain releaseObjectWithObjectId:(NSString *)objectId callback:(void (^)(id error))callback;
{
    callback(nil);
    
    [self _releaseObjectID:objectId];
}

- (void)domain:(PDRuntimeDomain *)domain releaseObjectGroupWithObjectGroup:(NSString *)objectGroup callback:(void (^)(id error))callback;
{
    callback(nil);
    
    [self _releaseObjectGroup:objectGroup];
}

// Evaluates expression on global object.
// Param expression: Expression to evaluate.
// Param objectGroup: Symbolic group name that can be used to release multiple objects.
// Param includeCommandLineAPI: Determines whether Command Line API should be available during the evaluation.
// Param doNotPauseOnExceptionsAndMuteConsole: Specifies whether evaluation should stop on exceptions and mute console. Overrides setPauseOnException state.
// Param contextId: Specifies in which isolated context to perform evaluation. Each content script lives in an isolated context and this parameter may be used to specify one of those contexts. If the parameter is omitted or 0 the evaluation will be performed in the context of the inspected page.
// Param returnByValue: Whether the result is expected to be a JSON object that should be sent by value.
// Callback Param result: Evaluation result.
// Callback Param wasThrown: True if the result was thrown during the evaluation.
- (void)domain:(PDRuntimeDomain *)domain evaluateWithExpression:(NSString *)expression objectGroup:(NSString *)objectGroup includeCommandLineAPI:(NSNumber *)includeCommandLineAPI doNotPauseOnExceptionsAndMuteConsole:(NSNumber *)doNotPauseOnExceptionsAndMuteConsole contextId:(NSNumber *)contextId returnByValue:(NSNumber *)returnByValue generatePreview:(NSNumber *)generatePreview callback:(void (^)(PDRuntimeRemoteObject *result, NSNumber *wasThrown, PDDebuggerExceptionDetails *exceptionDetails, id error))callback{
    NSLog(@"will eval expr = %@", expression);
    ChromeVirtualMachine *vm = [ChromeVirtualMachine sharedInstance];
    JSValue *value = [vm evaluateScript:expression];
    if([[value description] hasPrefix:@"function"] || [[value description] isEqualToString:@"[object GlobalObject]"]){
        callback([NSObject PD_remoteObjectRepresentationForObject:[value toString]], @(0), nil, nil);
    }
    else if(value.isArray){
        callback([NSObject PD_remoteObjectRepresentationForObject:value.toArray], @(0), nil, nil);
    }
    else{
        NSString *desc = [value.toObject description];
        if([desc hasPrefix:@"<__NSMallocBlock__"] || [desc hasPrefix:@"<__NSGlobalBlock__"]){
            callback([NSObject PD_remoteObjectRepresentationForObject:value.toString], @(0), nil, nil);
        }
        else{
            callback([NSObject PD_remoteObjectRepresentationForObject:value.toObject], @(0), nil, nil);
        }
    }
}

// Calls function with given declaration on the given object. Object group of the result is inherited from the target object.
// Param objectId: Identifier of the object to call function on.
// Param functionDeclaration: Declaration of the function to call.
// Param arguments: Call arguments. All call arguments must belong to the same JavaScript world as the target object.
// Param doNotPauseOnExceptionsAndMuteConsole: Specifies whether function call should stop on exceptions and mute console. Overrides setPauseOnException state.
// Param returnByValue: Whether the result is expected to be a JSON object which should be sent by value.
// Callback Param result: Call result.
// Callback Param wasThrown: True if the result was thrown during the evaluation.
- (void)domain:(PDRuntimeDomain *)domain callFunctionOnWithObjectId:(NSString *)objectId functionDeclaration:(NSString *)functionDeclaration arguments:(NSArray *)arguments doNotPauseOnExceptionsAndMuteConsole:(NSNumber *)doNotPauseOnExceptionsAndMuteConsole returnByValue:(NSNumber *)returnByValue callback:(void (^)(PDRuntimeRemoteObject *result, NSNumber *wasThrown, id error))callback{
    
}


#pragma mark - Public Methods

/**
 * Registers and returns a string associated with the object to retain.
 */
- (NSString *)registerAndGetKeyForObject:(id)object;
{
    NSString *key = [PDRuntimeDomainController _generateUUID];
    
    [self.objectReferences setObject:object forKey:key];
    
    return key;
}

/**
 * Clears object references given the string returned by registerAndGetKeyForObject:
 */
- (void)clearObjectReferencesByKey:(NSArray *)objectKeys;
{
    [self.objectReferences removeObjectsForKeys:objectKeys];
}

/**
 * Clears all object references.
 */
- (void)clearAllObjectReferences;
{
    [self.objectReferences removeAllObjects];
    [self.objectGroups removeAllObjects];
}

#pragma mark - Private Methods

- (void)_releaseObjectID:(NSString *)objectID;
{
    if (![self.objectReferences objectForKey:objectID]) {
        return;
    }
    
    [self.objectReferences removeObjectForKey:objectID];
}

- (void)_releaseObjectGroup:(NSString *)objectGroup;
{
    NSArray *objectIDs = [self.objectGroups objectForKey:objectGroup];
    if (objectIDs) {
        for (NSString *objectID in objectIDs) {
            [self _releaseObjectID:objectID];
        }
        
        [self.objectGroups removeObjectForKey:objectGroup];
    }
}

@end
