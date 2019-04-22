//
//  CRRulerLayer.h
//  Pods
//
//  Created by Sergey Chuchukalo on 08/25/2016.
//
//  Copyright © 2016 Cleveroad Inc. All rights reserved.

#import <QuartzCore/QuartzCore.h>
#import "CRMark.h"

@protocol CRRulerControlDataSource

- (NSString* __nullable)stringForMark:(NSNumber*)numberMark;

@end

@interface CRRulerLayer : CALayer

@property (nonatomic, weak) __nullable id<CRRulerControlDataSource> dataSource;

typedef struct CRRange {
    CGFloat location;
    CGFloat length;
} CRRange;

@property (nonatomic) CRRange rulerRange;

@property (nonatomic) CRMark *minorMark;
@property (nonatomic) CRMark *middleMark;
@property (nonatomic) CRMark *majorMark;

@end
