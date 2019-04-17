//
//  PDInputDomainController.m
//  PonyDebugger
//
//  Created by HUANG,Shaojun on 7/16/16.
//  Copyright © 2016 yidian. All rights reserved.
//

#import "PDInputDomainController.h"
#import "PDDebugger.h"
#import <UIKit/UIKit.h>
#import "ChromeVirtualMachine.h"
#import "PDDOMDomainController.h"
#import "PDConsoleDomainController.h"
#import "PDInspectorDomainController.h"
#import "PDRuntimeTypes.h"
#import "PDObject.h"
#import "NSObject+PDRuntimePropertyDescriptor.h"
#import "PDConsoleTypes.h"
#import <objc/runtime.h>

@interface PDDebugger ()

- (void)_resolveService:(NSNetService*)service;
- (void)_addController:(PDDomainController *)controller;
- (NSString *)_domainNameForController:(PDDomainController *)controller;
- (BOOL)_isTrackingDomainController:(PDDomainController *)controller;

@end

@interface PDDOMDomainController ()

// Use mirrored dictionaries to map between objets and node ids with fast lookup in both directions
@property (nonatomic, strong) NSMutableDictionary *objectsForNodeIds;
@property (nonatomic, strong) NSMutableDictionary *nodeIdsForObjects;
@property (nonatomic, assign) NSUInteger nodeIdCounter;

@property (nonatomic, strong) UIView *viewToHighlight;
@property (nonatomic, strong) UIView *highlightOverlay;

@property (nonatomic, assign) CGPoint lastPanPoint;
@property (nonatomic, assign) CGRect originalPinchFrame;
@property (nonatomic, assign) CGPoint originalPinchLocation;

@property (nonatomic, strong) UIView *inspectModeOverlay;

- (UIView *)chooseViewAtPoint:(CGPoint)point givenStartingView:(UIView *)startingView;
- (BOOL)shouldIgnoreView:(UIView *)view;

@end

@implementation PDInputDomainController

+ (Class)domainClass{
    return [PDInputDomain class];
}

+ (PDInputDomainController *)defaultInstance;
{
    static PDInputDomainController *defaultInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultInstance = [[PDInputDomainController alloc] init];
    });
    return defaultInstance;
}

- (void)enable{
    [[PDDebugger defaultInstance] performSelector:@selector(_addController:) withObject:self];
}

- (void)domain:(PDInputDomain *)domain dispatchKeyEventWithType:(NSString *)type modifiers:(NSNumber*)modifiers timestamp:(NSNumber*)timestamp text:(NSString*)text unmodifiedText:(NSString*)unmodifiedText keyIdentifier:(NSString*)keyIdentifier code:(NSString*)code key:(NSString*)key windowsVirtualKeyCode:(NSNumber*)windowsVirtualKeyCode nativeVirtualKeyCode:(NSNumber*)nativeVirtualKeyCode autoRepeat:(NSNumber*)autoRepeat isKeypad:(NSNumber*)isKeypad isSystemKey:(NSNumber*)isSystemKey callback:(void (^)(id error))callback{
    callback(nil);
}

- (NSArray<UIView*> *)chooseViewsAtPoint:(CGPoint)point givenStartingView:(UIView *)startingView;
{
    NSMutableArray *views = [[NSMutableArray alloc] init];
    PDDOMDomainController *domC = [PDDOMDomainController defaultInstance];
    // Look into the subviews (topmost first) to see if there's a view there that we should select
    for (UIView *subview in [startingView.subviews reverseObjectEnumerator]) {
        CGRect subviewFrameInWindowCoordinates = [startingView convertRect:subview.frame toView:nil];
        if (![domC shouldIgnoreView:subview] && !subview.hidden && subview.alpha > 0.0 && CGRectContainsPoint(subviewFrameInWindowCoordinates, point)) {
            
            if(subview.subviews.count > 0 || subview.subviews.count == 0)[views addObject:subview];
            if([subview isKindOfClass:[UIWebView class]] || [NSStringFromClass([subview class]) isEqualToString:@"WKWebView"]){
                return views;
            }
            [views addObjectsFromArray:[self chooseViewsAtPoint:point givenStartingView:subview]];
        }
    }
    
    // We didn't find anything in the subviews, so just return the starting view
    return views;
}

- (void)domain:(PDInputDomain *)domain dispatchMouseEventWithType:(NSString *)type x:(NSNumber *)x y:(NSNumber *)y modifiers:(NSNumber *)modifiers timestamp:(NSNumber *)timestamp button:(NSString *)button clickCount:(NSNumber *)clickCount callback:(void (^)(id error))callback{

    if(![type isEqualToString:@"mouseReleased"]){
        return;
    }
    
    CGPoint point = CGPointMake([x doubleValue],[y doubleValue]);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        PDDOMDomainController *domC = [PDDOMDomainController defaultInstance];
        PDInspectorDomain *inspectorDomain = [[PDInspectorDomainController defaultInstance] domain];
        
        
        PDRuntimeRemoteObject *remoteObject = [[PDRuntimeRemoteObject alloc] init];
        
        UIView *chosenView = [domC chooseViewAtPoint:point givenStartingView:[[UIApplication sharedApplication] keyWindow]];
        if (!chosenView) {
            return;
        }
        
        NSNumber *chosenNodeId = [domC.nodeIdsForObjects objectForKey:[NSValue valueWithNonretainedObject:chosenView]];
        
        remoteObject.type = @"object";
        remoteObject.subtype = @"node";
        remoteObject.objectId = [chosenNodeId stringValue];
        
        [inspectorDomain inspectWithObject:remoteObject hints:nil];
        
        [domC.domain inspectNodeRequestedWithBackendNodeId:chosenNodeId];

        if(chosenView){
            NSArray<UIView*> * views = [self chooseViewsAtPoint:point givenStartingView:[[UIApplication sharedApplication] keyWindow]];
            NSMutableArray<PDRuntimeRemoteObject*> *remoteObjectsConsole = [[NSMutableArray alloc] init];
            for (UIView *view in views) {
                PDRuntimeRemoteObject *remoteObjectConsole = [NSObject PD_remoteObjectRepresentationForObject:view];
                [remoteObjectsConsole addObject:remoteObjectConsole];
            }
            PDConsoleDomainController *consoleC = [PDConsoleDomainController defaultInstance];
            PDConsoleDomain *console = [consoleC domain];
            PDConsoleConsoleMessage *msg = [[PDConsoleConsoleMessage alloc] init];
            msg.source = @"other";
            msg.level = @"log";
            msg.text = @"";
            msg.parameters = remoteObjectsConsole;
            [console messageAddedWithMessage:msg];
        }
        
    });
    callback(nil);
}

- (void)domain:(PDInputDomain *)domain emulateTouchFromMouseEventWithType:(NSString *)type x:(NSNumber *)x y:(NSNumber *)y timestamp:(NSNumber *)timestamp button:(NSString *)button deltaX:(NSNumber *)deltaX deltaY:(NSNumber *)deltaY modifiers:(NSNumber *)modifiers clickCount:(NSNumber *)clickCount callback:(void (^)(id error))callback{
    [self domain:domain dispatchMouseEventWithType:type x:x y:y modifiers:modifiers timestamp:timestamp button:button clickCount:clickCount callback:callback];
}
@end
