//
//  PDPageDomainController.m
//  PonyDebugger
//
//  Created by Wen-Hao Lue on 8/6/12.
//
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import "PDDOMDomainController.h"
#import "PDPageDomainController.h"
#import "PDRuntimeDomainController.h"
#import "PDPageDomain.h"
#import "PDPageTypes.h"
#import <UIKit/UIKit.h>

@interface PDPageDomainController () <PDPageCommandDelegate>
@end


@implementation PDPageDomainController

@dynamic domain;

#pragma mark - Statics

+ (PDPageDomainController *)defaultInstance;
{
    static PDPageDomainController *defaultInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultInstance = [[PDPageDomainController alloc] init];
    });
    
    return defaultInstance;
}

+ (Class)domainClass;
{
    return [PDPageDomain class];
}

- (NSArray*)resourceTreesForPath:(NSString*)path{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    NSFileManager *fm;
    fm = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator<NSString *> *subdirs = [[NSFileManager defaultManager] enumeratorAtPath:path];
    for(NSString *subdir in subdirs){
        NSString *subpath = [path stringByAppendingPathComponent:subdir];
        BOOL isSubDirDir;
        BOOL exists = [fm fileExistsAtPath:subpath isDirectory:&isSubDirDir];
        if(exists){
            if(!isSubDirDir){
                PDPageFrame *frame = [[PDPageFrame alloc] init];
                
                frame.identifier = [NSString stringWithFormat:@"%d", 1];
                frame.name = path;
                frame.securityOrigin = [[NSBundle mainBundle] bundleIdentifier];
                frame.url = subpath;
                frame.loaderId = @"0";
                frame.mimeType = @"";
                
                PDPageFrameResourceTree *resourceTree = [[PDPageFrameResourceTree alloc] init];
                resourceTree.frame = frame;
                resourceTree.resources = @[];
                resourceTree.childFrames = @[];
                [arr addObject:resourceTree];
            }
        }
    }
    
    return arr;
}

#pragma mark - PDPageCommandDelegate

- (void)domain:(PDPageDomain *)domain getResourceTreeWithCallback:(void (^)(PDPageFrameResourceTree *, id))callback;
{
    PDPageFrame *frame = [[PDPageFrame alloc] init];
    
    frame.identifier = @"0";
    frame.name = @"Root";
    frame.securityOrigin = [[NSBundle mainBundle] bundleIdentifier];
    frame.url = [[NSBundle mainBundle] bundlePath];
    frame.loaderId = @"0";
    frame.mimeType = @"";
    
    PDPageFrameResourceTree *resourceTree = [[PDPageFrameResourceTree alloc] init];
    resourceTree.frame = frame;
    resourceTree.resources = @[];
    resourceTree.childFrames = [self resourceTreesForPath:NSHomeDirectory()];
    resourceTree.childFrames = [resourceTree.childFrames arrayByAddingObjectsFromArray:[self resourceTreesForPath:[frame.url stringByAppendingString:@"/"]]];

    resourceTree.resources = @[@{
        @"url": [[NSBundle mainBundle] bundleURL].absoluteString,
        @"type": @"Document",
        @"mimeType": @"",
        },];
    
    callback(resourceTree, nil);
}

- (void)domain:(PDPageDomain *)domain reloadWithIgnoreCache:(NSNumber *)ignoreCache scriptToEvaluateOnLoad:(NSString *)scriptToEvaluateOnLoad callback:(void (^)(id))callback;
{
    callback(nil);
}


- (void)domain:(PDPageDomain *)domain getResourceContentWithFrameId:(NSString *)frameId url:(NSString *)url callback:(void (^)(NSString *content, NSNumber *base64Encoded, id error))callback{
    
    if([url isEqualToString:[[NSBundle mainBundle] bundlePath]]){
        //return info.plust
        NSString *infoPlistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        id plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfFile:infoPlistPath] options:0 format:nil error:nil];
        if(plist){
            NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListXMLFormat_v1_0 options:0 error:nil];
            if(xmlData){
                callback([[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding], @(0), nil);
            }
            else{
                callback(@"", @(0), nil);
            }
        }
        else{
            callback(@"", @(0), nil);
        }
        return;
    }
    
    NSFileManager *fm;
    fm = [NSFileManager defaultManager];
    BOOL isSubDirDir;
    BOOL exists = [fm fileExistsAtPath:url isDirectory:&isSubDirDir];
    if(exists){
        if(!isSubDirDir){
            
            id plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfFile:url] options:0 format:nil error:nil];
            if(plist){
                NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListXMLFormat_v1_0 options:0 error:nil];
                if(xmlData){
                    callback([[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding], @(0), nil);
                }
            }
            else{
                NSString *content = [NSString stringWithContentsOfFile:url encoding:NSUTF8StringEncoding error:nil];
                if(content){
                    callback(content, @(0), nil);
                    return;
                }
                else{
                    content = [NSString stringWithContentsOfFile:url encoding:NSASCIIStringEncoding error:nil];
                    if(content){
                        callback(content, @(0), nil);
                        return;
                    }
                    else{
                        NSData *data = [NSData dataWithContentsOfFile:url];
                        if(data){
                            callback([data description], @(0), nil);
                            return;
                        }
                    }
                }
            }
        }
    }
    if(isSubDirDir){
        callback([NSString stringWithFormat:@"<html>This is a directory, %@</html>", url], @(NO), nil);
    }
    else{
        callback([NSString stringWithFormat:@"<html>Content here. %@</html>", url], @(NO), nil);
    }
}

- (UIWindow *)statusWindow
{
    NSString *statusBarString = [NSString stringWithFormat:@"_statusBarWindow"];
    return [[UIApplication sharedApplication] valueForKey:statusBarString];
}

static BOOL screencastAckRecv = YES;

- (void)screencastFrame{
    if(screencastAckRecv == NO)return;
    screencastAckRecv = NO;
    
    dispatch_async(dispatch_get_main_queue(),^{
        
        NSArray *systemWindows = [PDDOMDomainController defaultInstance].systemWindows;
        
        NSArray<UIWindow*> *windows = [[UIApplication sharedApplication] windows];
        windows = [windows arrayByAddingObject:[self statusWindow]];
        windows = [windows arrayByAddingObjectsFromArray:systemWindows];
        windows = [windows sortedArrayUsingComparator:^NSComparisonResult(UIWindow * _Nonnull obj1, UIWindow *  _Nonnull obj2) {
            if (obj1.windowLevel > obj2.windowLevel) {
                return NSOrderedDescending;
            }
            if (obj1.windowLevel < obj2.windowLevel) {
                return NSOrderedAscending;
            }
            return NSOrderedSame;
        }];
        
        CGRect rect = [[UIScreen mainScreen] bounds];
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 1.0);
        
        for (UIWindow *keyWindow in windows) {
            
            CGContextRef context = UIGraphicsGetCurrentContext();
            [keyWindow.layer renderInContext:context];
        }
        
        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        NSData *data = UIImageJPEGRepresentation(img, 0.5);
        NSString *dataBase64 = [data base64EncodedStringWithOptions:0];
        CGSize size = [UIScreen mainScreen].bounds.size;
        screencastAckRecv = NO;
        [self.domain.debuggingServer sendEventWithName:@"Page.screencastFrame" parameters:@{@"data":dataBase64, @"metadata":@{@"offsetTop":@0,@"pageScaleFactor":@1,@"deviceWidth":@(size.width), @"deviceHeight":@(size.height),@"scrollOffsetX":@0,@"scrollOffsetY":@0}, @"sessionId":@1}];
    });
}

static NSTimer *screencastTimer;
static NSTimeInterval lastScreenCastTime = 0;

- (void)domain:(PDPageDomain *)domain startScreencast:(void (^)(id error))callback{
    if(screencastTimer == nil){
        //每秒最多20 frames
        screencastTimer = [NSTimer timerWithTimeInterval:0.05 target:self selector:@selector(screencastFrame) userInfo:nil repeats:YES];
        screencastAckRecv = YES;
        [[NSRunLoop currentRunLoop] addTimer:screencastTimer forMode:NSRunLoopCommonModes];
    }
    
    callback(nil);
}

- (void)domain:(PDPageDomain *)domain screencastFrameAck:(void (^)(id error))callback{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        screencastAckRecv = YES;
    });
    callback(nil);
}

- (void)domain:(PDPageDomain *)domain stopScreencast:(void (^)(id error))callback{
    [screencastTimer invalidate];
    screencastTimer = nil;
    screencastAckRecv = YES;
    lastScreenCastTime = [[NSDate date] timeIntervalSince1970];
    callback(nil);
}


- (void)domain:(PDPageDomain *)domain canScreencastWithCallback:(void (^)(NSNumber *, id))callback;
{
    callback(@YES, nil);
}


@end
