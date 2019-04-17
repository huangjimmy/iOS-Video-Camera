//
//  PDDOMStorageDomain.h
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

@class PDDOMStorageStorageId;

@protocol PDDOMStorageCommandDelegate;

// Query and modify DOM storage.
@interface PDDOMStorageDomain : PDDynamicDebuggerDomain 

@property (nonatomic, assign) id <PDDOMStorageCommandDelegate, PDCommandDelegate> delegate;

// Events
- (void)domStorageItemsClearedWithStorageId:(PDDOMStorageStorageId *)storageId;
- (void)domStorageItemRemovedWithStorageId:(PDDOMStorageStorageId *)storageId key:(NSString *)key;
- (void)domStorageItemAddedWithStorageId:(PDDOMStorageStorageId *)storageId key:(NSString *)key newValue:(NSString *)newValue;
- (void)domStorageItemUpdatedWithStorageId:(PDDOMStorageStorageId *)storageId key:(NSString *)key oldValue:(NSString *)oldValue newValue:(NSString *)newValue;

@end

@protocol PDDOMStorageCommandDelegate <PDCommandDelegate>
@optional

/// Enables storage tracking, storage events will now be delivered to the client.
- (void)domain:(PDDOMStorageDomain *)domain enableWithCallback:(void (^)(id error))callback;

/// Disables storage tracking, prevents storage events from being sent to the client.
- (void)domain:(PDDOMStorageDomain *)domain disableWithCallback:(void (^)(id error))callback;

- (void)domain:(PDDOMStorageDomain *)domain getDOMStorageEntriesWithStorageId:(NSString *)storageId callback:(void (^)(NSArray *entries, id error))callback;
- (void)domain:(PDDOMStorageDomain *)domain setDOMStorageItemWithStorageId:(NSString *)storageId key:(NSString *)key value:(NSString *)value callback:(void (^)(NSNumber *success, id error))callback;
- (void)domain:(PDDOMStorageDomain *)domain removeDOMStorageItemWithStorageId:(NSString *)storageId key:(NSString *)key callback:(void (^)(NSNumber *success, id error))callback;
- (void)domain:(PDDOMStorageDomain *)domain getDOMStorageItemsWithStorageId:(NSDictionary *)storageId callback:(void (^)(NSArray *entries, id error))callback;


@end

@interface PDDebugger (PDDOMStorageDomain)

@property (nonatomic, readonly, strong) PDDOMStorageDomain *DOMStorageDomain;

@end
