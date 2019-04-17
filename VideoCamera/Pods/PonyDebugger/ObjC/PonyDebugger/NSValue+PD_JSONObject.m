//
//  NSValue+PD_JSONObject.m
//  PonyDebugger
//
//  Created by huangshaojun on 7/15/16.
//  Copyright © 2016 yidian. All rights reserved.
//

#import "NSValue+PD_JSONObject.h"

@implementation NSValue (PD_JSONObject)

- (id)PD_JSONObject;
{
    if([self isKindOfClass:[NSNumber class]]){
        return self;
    }
    return self.description;
}

@end
