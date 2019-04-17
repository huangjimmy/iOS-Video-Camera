//
//  NSDictionary+PD_JSONObject.m
//  PonyDebugger
//
//  Created by huangshaojun on 7/15/16.
//  Copyright © 2016 yidian. All rights reserved.
//

#import "PDObject.h"
#import "NSDictionary+PD_JSONObject.h"

@implementation NSDictionary (PD_JSONObject)

- (id)PD_JSONObject
{
    NSMutableDictionary *newResult = [[NSMutableDictionary alloc] initWithCapacity:self.count];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id val, BOOL *stop) {
        [newResult setObject:[val PD_JSONObjectCopy] forKey:key];
    }];
    return newResult;
}

@end
