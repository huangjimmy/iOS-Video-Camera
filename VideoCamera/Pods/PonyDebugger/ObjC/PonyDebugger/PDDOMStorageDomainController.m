//
//  PDDOMStorageDomainController.m
//  PonyDebugger
//
//  Created by huangshaojun on 7/12/16.
//  Copyright © 2016 yidian. All rights reserved.
//

#import "PDDOMStorageDomainController.h"
#import "PDDebugger.h"

@interface PDDebugger ()

- (void)_resolveService:(NSNetService*)service;
- (void)_addController:(PDDomainController *)controller;
- (NSString *)_domainNameForController:(PDDomainController *)controller;
- (BOOL)_isTrackingDomainController:(PDDomainController *)controller;

@end

@implementation PDDOMStorageDomainController

+ (Class)domainClass{
    return [PDDOMStorageDomain class];
}

+ (instancetype)defaultInstance;
{
    static PDDOMStorageDomainController *defaultInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultInstance = [[PDDOMStorageDomainController alloc] init];
    });
    return defaultInstance;
}

- (void)enable{
    [[PDDebugger defaultInstance] performSelector:@selector(_addController:) withObject:self];
}




- (void)domain:(PDDOMStorageDomain *)domain enableWithCallback:(void (^)(id error))callback{
    callback(nil);
}

- (void)domain:(PDDOMStorageDomain *)domain disableWithCallback:(void (^)(id error))callback{
    callback(nil);
}

//this method is for chrome debugger protocol v1.1
- (void)domain:(PDDOMStorageDomain *)domain getDOMStorageItemsWithStorageId:(NSDictionary *)storageId callback:(void (^)(NSArray *entries, id error))callback{
    
    BOOL isLocalStorage = [storageId[@"isLocalStorage"] boolValue];
    if(isLocalStorage){
        //NSUserDefaults
        NSDictionary<NSString*, id> *localStorage = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
        NSMutableArray *entries = [[NSMutableArray alloc] init];
        for (NSString *key in localStorage.allKeys) {
            id value = localStorage[key];
            NSString *desc = [value description];
            if([value isKindOfClass:[NSData class]]){
                @try {
                    id obj = [NSKeyedUnarchiver unarchiveObjectWithData:value];
                    NSString *desc2 = [obj description];
                    if(desc2)desc = desc2;
                } @catch (NSException *exception) {
                    
                } @finally {
                    
                }
                
            }
            NSArray *item = @[key, desc];
            [entries addObject:item];
        }
        
        callback(entries, nil);
    }
    else{
        //cookies
        callback(@[], nil);
    }
    NSLog(@"");
}

- (void)domain:(PDDOMStorageDomain *)domain getDOMStorageEntriesWithStorageId:(NSString *)storageId callback:(void (^)(NSArray *entries, id error))callback{
    NSLog(@"");
}

- (void)domain:(PDDOMStorageDomain *)domain setDOMStorageItemWithStorageId:(NSString *)storageId key:(NSString *)key value:(NSString *)value callback:(void (^)(NSNumber *success, id error))callback{
    if([storageId isKindOfClass:[NSDictionary class]]){
        //protocol v1.1
        id oldValue = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if([oldValue isKindOfClass:[NSString class]]){
            [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
            callback(@(YES), nil);
        }
        else if([oldValue isKindOfClass:[NSNumber class]]){
            
            [[NSUserDefaults standardUserDefaults] setObject:@([value doubleValue]) forKey:key];
            callback(@(YES), nil);
        }
        else{
            callback(@(NO), @"unsupported");
        }
    }
    else{
        //older protocol, not supported
        callback(@(NO), @"unsupported");
    }
}

- (void)domain:(PDDOMStorageDomain *)domain removeDOMStorageItemWithStorageId:(NSString *)storageId key:(NSString *)key callback:(void (^)(NSNumber *success, id error))callback{
    NSLog(@"");
}

@end
