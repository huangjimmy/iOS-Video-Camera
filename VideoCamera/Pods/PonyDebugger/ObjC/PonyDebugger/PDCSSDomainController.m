//
//  PDCSSDomainController.m
//  YAInspector
//
//  Created by HUANG,Shaojun on 7/17/16.
//  Copyright © 2016 yidian. All rights reserved.
//

#import "PDCSSDomainController.h"
#import "PDDOMDomainController.h"
#import "PDCSSTypes.h"
#import <UIKit/UIKit.h>
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



@implementation PDCSSDomainController
@dynamic domain;

+ (Class)domainClass{
    return [PDCSSDomain class];
}

+ (PDCSSDomainController *)defaultInstance;
{
    static PDCSSDomainController *defaultInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultInstance = [[PDCSSDomainController alloc] init];
    });
    return defaultInstance;
}

- (void)enable{
    [[PDDebugger defaultInstance] performSelector:@selector(_addController:) withObject:self];
}



#pragma PDCommandDelegate

/// Enables the CSS agent for the given page. Clients should not assume that the CSS agent has been enabled until the result of this command is received.
- (void)domain:(PDCSSDomain *)domain enableWithCallback:(void (^)(id error))callback{
    callback(nil);
}

/// Disables the CSS agent for the given page.
- (void)domain:(PDCSSDomain *)domain disableWithCallback:(void (^)(id error))callback{
    callback(nil);
}

/// Returns requested styles for a DOM node identified by <code>nodeId</code>.
// Param excludePseudo: Whether to exclude pseudo styles (default: false).
// Param excludeInherited: Whether to exclude inherited styles (default: false).
// Callback Param matchedCSSRules: CSS rules matching this node, from all applicable stylesheets.
// Callback Param pseudoElements: Pseudo style matches for this node.
// Callback Param inherited: A chain of inherited styles (from the immediate node parent up to the DOM tree root).
- (void)domain:(PDCSSDomain *)domain getMatchedStylesForNodeWithNodeId:(NSNumber *)nodeId excludePseudo:(NSNumber *)excludePseudo excludeInherited:(NSNumber *)excludeInherited callback:(void (^)(PDCSSCSSStyle *inlineStyle, NSArray *matchedCSSRules, NSArray *pseudoElements, NSArray *inherited, id error))callback{
    return [self domain:domain getInlineStylesForNodeWithNodeId:nodeId callback:^(PDCSSCSSStyle *inlineStyle, PDCSSCSSStyle *a, id error){
        callback(inlineStyle, nil, nil, nil, nil);
    }];
}

/// Returns the styles defined inline (explicitly in the "style" attribute and implicitly, using DOM attributes) for a DOM node identified by <code>nodeId</code>.
// Callback Param inlineStyle: Inline style for the specified DOM node.
// Callback Param attributesStyle: Attribute-defined element style (e.g. resulting from "width=20 height=100%").
- (void)domain:(PDCSSDomain *)domain getInlineStylesForNodeWithNodeId:(NSNumber *)nodeId callback:(void (^)(PDCSSCSSStyle *inlineStyle, PDCSSCSSStyle *attributesStyle, id error))callback{
#define PROP2STR(a) if(integerValue == a){ \
property.value = @#a; \
}
    
#define PROP2STR_STATE(a) if(integerValue & a){ \
property.value = [NSString stringWithFormat:@"%@%@%@",property.value, property.value.length>0?@"|":@"" , @#a]; \
}
    
    PDDOMDomainController *domC = [PDDOMDomainController defaultInstance];
    UIView *view = [domC.objectsForNodeIds objectForKey:nodeId];
    if (view == nil) {
        if([nodeId integerValue] == 1){
            PDCSSCSSStyle *inlineStyle = [[PDCSSCSSStyle alloc] init];
            inlineStyle.styleSheetId = @"";
            inlineStyle.cssProperties = @[];
            
            {
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"UIApplication.statusBarStyle";
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
                NSInteger integerValue = [UIApplication sharedApplication].statusBarStyle;
                PROP2STR(UIStatusBarStyleDefault);//                                    = 0, // Dark content, for use on light backgrounds
                PROP2STR(UIStatusBarStyleLightContent);//     NS_ENUM_AVAILABLE_IOS(7_0) = 1, // Light content, for use on dark backgrounds
                
                PROP2STR(UIStatusBarStyleBlackTranslucent);// NS_ENUM_DEPRECATED_IOS(2_0, 7_0, "Use UIStatusBarStyleLightContent") = 1,
                PROP2STR(UIStatusBarStyleBlackOpaque);//      NS_ENUM_DEPRECATED_IOS(2_0, 7_0, "Use UIStatusBarStyleLightContent") = 2,
            }
            {
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"UIApplication.statusBarOrientation";
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
                NSInteger integerValue = [UIApplication sharedApplication].statusBarOrientation;
                PROP2STR(UIInterfaceOrientationUnknown);//            = UIDeviceOrientationUnknown,
                PROP2STR(UIInterfaceOrientationPortrait);//           = UIDeviceOrientationPortrait,
                PROP2STR(UIInterfaceOrientationPortraitUpsideDown);// = UIDeviceOrientationPortraitUpsideDown,
                PROP2STR(UIInterfaceOrientationLandscapeLeft);//      = UIDeviceOrientationLandscapeRight,
                PROP2STR(UIInterfaceOrientationLandscapeRight);//     = UIDeviceOrientationLandscapeLeft
            }
            {
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"UIApplication.userInterfaceLayoutDirection";
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
                NSInteger integerValue = [UIApplication sharedApplication].userInterfaceLayoutDirection;
                PROP2STR(UIUserInterfaceLayoutDirectionLeftToRight);//
                PROP2STR(UIUserInterfaceLayoutDirectionRightToLeft);//
            }
            {
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"UIApplication.preferredContentSizeCategory";
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
                property.value = [UIApplication sharedApplication].preferredContentSizeCategory;
            }
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            for (NSString *key in infoDictionary) {
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = key;
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
                property.value = [infoDictionary[key] description];
            }
            
            {
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"UIApplication.preferredContentSizeCategory";
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
                property.value = [UIApplication sharedApplication].preferredContentSizeCategory;
            }
            
            inlineStyle.shorthandEntries = @[];
            callback(inlineStyle, nil, nil);
        }
        else
            callback(nil, nil, nil);
    }
    else{
        dispatch_async(dispatch_get_main_queue(), ^{

            PDCSSCSSStyle *inlineStyle = [[PDCSSCSSStyle alloc] init];
            inlineStyle.styleSheetId = @"";
            
            PDCSSCSSComputedStyleProperty *widthProperty = [[PDCSSCSSComputedStyleProperty alloc] init];
            widthProperty.name = @"width";
            widthProperty.value = [NSString stringWithFormat:@"%.2f", view.frame.size.width];
            
            PDCSSCSSComputedStyleProperty *heightProperty = [[PDCSSCSSComputedStyleProperty alloc] init];
            heightProperty.name = @"height";
            heightProperty.value = [NSString stringWithFormat:@"%.2f", view.frame.size.height];
            
            PDCSSCSSComputedStyleProperty *topProperty = [[PDCSSCSSComputedStyleProperty alloc] init];
            topProperty.name = @"top";
            topProperty.value = [NSString stringWithFormat:@"%.2f", view.frame.origin.y];
            
            PDCSSCSSComputedStyleProperty *leftProperty = [[PDCSSCSSComputedStyleProperty alloc] init];
            leftProperty.name = @"left";
            leftProperty.value = [NSString stringWithFormat:@"%.2f", view.frame.origin.x];
            
            CGFloat r,g,b,a;
            UIColor *c;
            PDCSSCSSComputedStyleProperty *colorProperty = nil;
            BOOL converted;
            
            PDCSSCSSComputedStyleProperty *backgroundColorProperty = [[PDCSSCSSComputedStyleProperty alloc] init];
            backgroundColorProperty.name = @"backgroundColor";
            c = view.backgroundColor;
            colorProperty = backgroundColorProperty;
            converted = [c getRed:&r green:&g blue:&b alpha:&a];
            if(converted){
                colorProperty.value = [NSString stringWithFormat:@"rgba(%.2f,%.2f,%.2f,%.2f)", r*255,g*255,b*255,a];
            }
            else if(c){
                colorProperty.value = @"[pattern color]";
            }
            else{
                colorProperty.value = @"nil";
            }
            
            PDCSSCSSComputedStyleProperty *borderWidthProperty = [[PDCSSCSSComputedStyleProperty alloc] init];
            borderWidthProperty.name = @"borderWidth";
            borderWidthProperty.value = [NSString stringWithFormat:@"%f", view.layer.borderWidth];
            
            PDCSSCSSComputedStyleProperty *borderColorProperty = [[PDCSSCSSComputedStyleProperty alloc] init];
            borderColorProperty.name = @"borderColor";
            colorProperty = borderColorProperty;
            c = [UIColor colorWithCGColor:view.layer.backgroundColor];
            converted = [c getRed:&r green:&g blue:&b alpha:&a];
            if(converted){
                colorProperty.value = [NSString stringWithFormat:@"rgba(%.2f,%.2f,%.2f,%.2f)", r*255,g*255,b*255,a];
            }
            else if(c){
                colorProperty.value = @"[pattern color]";
            }
            else{
                colorProperty.value = @"nil";
            }
            
            PDCSSCSSComputedStyleProperty *cornerRadiusProperty = [[PDCSSCSSComputedStyleProperty alloc] init];
            cornerRadiusProperty.name = @"cornerRadius";
            cornerRadiusProperty.value = [NSString stringWithFormat:@"%.2f", view.layer.cornerRadius];
            
            inlineStyle.cssProperties = @[widthProperty, heightProperty, topProperty, leftProperty, backgroundColorProperty, borderWidthProperty, borderColorProperty, cornerRadiusProperty];
            inlineStyle.shorthandEntries = @[];
            
            if([(id)view respondsToSelector:@selector(textColor)]){
                PDCSSCSSComputedStyleProperty *textColorProperty = [[PDCSSCSSComputedStyleProperty alloc] init];
                textColorProperty.name = @"textColor";
                colorProperty = textColorProperty;
                c = [(id)view textColor];
                converted = [c getRed:&r green:&g blue:&b alpha:&a];
                if(converted){
                    colorProperty.value = [NSString stringWithFormat:@"rgba(%.2f,%.2f,%.2f,%.2f)", r*255,g*255,b*255,a];
                }
                else if(c){
                    colorProperty.value = @"[pattern color]";
                }
                else{
                    colorProperty.value = @"nil";
                }
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:textColorProperty];
            }
            
            if([(id)view respondsToSelector:@selector(tintColor)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"tintColor";
                colorProperty = property;
                c = [(id)view tintColor];
                converted = [c getRed:&r green:&g blue:&b alpha:&a];
                if(converted){
                    colorProperty.value = [NSString stringWithFormat:@"rgba(%.2f,%.2f,%.2f,%.2f)", r*255,g*255,b*255,a];
                }
                else if(c){
                    colorProperty.value = @"[pattern color]";
                }
                else{
                    colorProperty.value = @"nil";
                }
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            
            if([(id)view respondsToSelector:@selector(text)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"text";
                property.value = [(id)view text];
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            if([(id)view respondsToSelector:@selector(frame)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"frame";
                property.value = NSStringFromCGRect([view frame]);
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            if([(id)view respondsToSelector:@selector(bounds)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"bounds";
                property.value = NSStringFromCGRect([view bounds]);
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            if([(id)view respondsToSelector:@selector(center)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"center";
                property.value = NSStringFromCGPoint([view center]);
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            
            if([(id)view respondsToSelector:@selector(contentSize)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"contentSize";
                property.value = NSStringFromCGSize([(id)view contentSize]);
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            
            if([(id)view respondsToSelector:@selector(contentOffset)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"contentOffset";
                property.value = NSStringFromCGPoint([(id)view contentOffset]);
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            
            if([(id)view respondsToSelector:@selector(contentInset)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"contentInset";
                property.value = NSStringFromUIEdgeInsets([(id)view contentInset]);
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            
            if([(id)view respondsToSelector:@selector(attributedText)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"attributedText";
                property.value = [[(id)view attributedText] description];
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            
            if([view respondsToSelector:@selector(isHidden)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"hidden";
                property.value = view.hidden?@"true":@"false";
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            
            if([view respondsToSelector:@selector(isOpaque)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"opaque";
                property.value = view.opaque?@"true":@"false";
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            
            if([view respondsToSelector:@selector(alpha)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"alpha";
                property.value = [NSString stringWithFormat:@"%f", view.alpha];
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            if([(id)view respondsToSelector:@selector(accessibilityIdentifier)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"accessibilityIdentifier";
                property.value = [(id)view accessibilityIdentifier];
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            
            if([view respondsToSelector:@selector(tag)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"tag";
                property.value = [NSString stringWithFormat:@"%ld", view.tag];
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            
            {
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"class";
                property.value = NSStringFromClass([view class]);
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            
            {
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                property.name = @"superclass";
                property.value = NSStringFromClass([view superclass]);
                Class superclass = [view superclass];
                superclass = class_getSuperclass(superclass);
                while (superclass && superclass != [NSObject class]) {
                    property.value = [NSString stringWithFormat:@"%@, %@",property.value, NSStringFromClass(superclass)];
                    superclass = class_getSuperclass(superclass);
                }
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            
            if([view respondsToSelector:@selector(contentMode)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                NSInteger integerValue = view.contentMode;
                property.name = @"contentMode";
                PROP2STR(UIViewContentModeScaleToFill)
                PROP2STR(UIViewContentModeScaleAspectFit)     // contents scaled to fit with fixed aspect. remainder is transparent
                PROP2STR(UIViewContentModeScaleAspectFill)     // contents scaled to fill with fixed aspect. some portion of content may be clipped.
                PROP2STR(UIViewContentModeRedraw)              // redraw on bounds change (calls -setNeedsDisplay)
                PROP2STR(UIViewContentModeCenter)              // contents remain same size. positioned adjusted.
                PROP2STR(UIViewContentModeTop)
                PROP2STR(UIViewContentModeBottom)
                PROP2STR(UIViewContentModeLeft)
                PROP2STR(UIViewContentModeRight)
                PROP2STR(UIViewContentModeTopLeft)
                PROP2STR(UIViewContentModeTopRight)
                PROP2STR(UIViewContentModeBottomLeft)
                PROP2STR(UIViewContentModeBottomRight)
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            
            if([view respondsToSelector:@selector(state)]){
                PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                NSInteger integerValue = [(id)view state];
                property.name = @"UIControl.state";
                property.value = @"";
                PROP2STR(UIControlStateNormal);//       = 0,
                PROP2STR_STATE(UIControlStateHighlighted);//  = 1 << 0,                  // used when UIControl isHighlighted is set
                PROP2STR_STATE(UIControlStateDisabled);//     = 1 << 1,
                PROP2STR_STATE(UIControlStateSelected);//     = 1 << 2,                  // flag usable by app (see below)
                PROP2STR_STATE(UIControlStateFocused);// NS_ENUM_AVAILABLE_IOS(9_0) = 1 << 3, // Applicable only when the screen supports focus
                inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
            }
            
            if([view isKindOfClass:[UILabel class]]){
                int i = 0;
                NSArray *uilabelProps = @[@"textAlignment", @"numberOfLines", @"lineBreakMode", @"font"];
                for (NSString *propName in uilabelProps) {
                    id value = [view valueForKey:propName];
                    PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                    property.name = propName;
                    switch (i) {
                        case 0:
                        {
                            NSInteger integerValue = [value integerValue];
                            PROP2STR(NSTextAlignmentLeft);
                            PROP2STR(NSTextAlignmentCenter);
                            PROP2STR(NSTextAlignmentRight);
                            PROP2STR(NSTextAlignmentJustified);
                            PROP2STR(NSTextAlignmentNatural);
                        }
                            break;
                        case 2:
                            /*
                             NSLineBreakByWordWrapping = 0,     	// Wrap at word boundaries, default
                             NSLineBreakByCharWrapping,		// Wrap at character boundaries
                             NSLineBreakByClipping,		// Simply clip
                             NSLineBreakByTruncatingHead,	// Truncate at head of line: "...wxyz"
                             NSLineBreakByTruncatingTail,	// Truncate at tail of line: "abcd..."
                             NSLineBreakByTruncatingMiddle	// Truncate middle of line:  "ab...yz"
                             */
                        {
                            NSInteger integerValue = [value integerValue];
                            PROP2STR(NSLineBreakByWordWrapping);
                            PROP2STR(NSLineBreakByCharWrapping);
                            PROP2STR(NSLineBreakByClipping);
                            PROP2STR(NSLineBreakByTruncatingHead);
                            PROP2STR(NSLineBreakByTruncatingTail);
                            PROP2STR(NSLineBreakByTruncatingMiddle);
                        }
                            break;
                        default:
                            property.value = [value description];
                            break;
                    }
                    inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
                    i++;
                }
            }
            
            if([view isKindOfClass:[UITextView class]]){
                int i = 0;
                NSArray *uilabelProps = @[@"textAlignment", @"font", @"lineBreakMode"];
                for (NSString *propName in uilabelProps) {
                    id value = [view valueForKey:propName];
                    PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                    property.name = propName;
                    switch (i) {
                        case 0:
                        {
                            NSInteger integerValue = [value integerValue];
                            PROP2STR(NSTextAlignmentLeft);
                            PROP2STR(NSTextAlignmentCenter);
                            PROP2STR(NSTextAlignmentRight);
                            PROP2STR(NSTextAlignmentJustified);
                            PROP2STR(NSTextAlignmentNatural);
                        }
                            break;
                        case 2:
                            /*
                             NSLineBreakByWordWrapping = 0,     	// Wrap at word boundaries, default
                             NSLineBreakByCharWrapping,		// Wrap at character boundaries
                             NSLineBreakByClipping,		// Simply clip
                             NSLineBreakByTruncatingHead,	// Truncate at head of line: "...wxyz"
                             NSLineBreakByTruncatingTail,	// Truncate at tail of line: "abcd..."
                             NSLineBreakByTruncatingMiddle	// Truncate middle of line:  "ab...yz"
                             */
                        {
                            NSInteger integerValue = [value integerValue];
                            PROP2STR(NSLineBreakByWordWrapping);
                            PROP2STR(NSLineBreakByCharWrapping);
                            PROP2STR(NSLineBreakByClipping);
                            PROP2STR(NSLineBreakByTruncatingHead);
                            PROP2STR(NSLineBreakByTruncatingTail);
                            PROP2STR(NSLineBreakByTruncatingMiddle);
                        }
                            break;
                        default:
                            property.value = [value description];
                            break;
                    }
                    inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
                    i++;
                }
            }
            
            NSArray *constraints = view.constraints;
            if(constraints.count > 0){
                for(NSUInteger i=0;i<constraints.count;i++){
                    {
                        PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
                        property.name = [NSString stringWithFormat:@"UIView.constraints[%zd]", i];
                        property.value = [constraints[i] description];
                        inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
                    }
                }
            }
            
            inlineStyle.cssProperties = [inlineStyle.cssProperties sortedArrayUsingComparator:^(id obj1, id obj2){
                return [[obj1 name] compare:[obj2 name]];
            }];
            callback(inlineStyle, nil, nil);

        });
    }
}

/// Returns the computed style for a DOM node identified by <code>nodeId</code>.
// Callback Param computedStyle: Computed style for the specified DOM node.
- (void)domain:(PDCSSDomain *)domain getComputedStyleForNodeWithNodeId:(NSNumber *)nodeId callback:(void (^)(NSArray *computedStyle, id error))callback{
    return [self domain:domain getInlineStylesForNodeWithNodeId:nodeId callback:^(PDCSSCSSStyle *inlineStyle, PDCSSCSSStyle *a, id error){
        for (NSString *zeros in @[@"padding-top",@"padding", @"padding-left",@"padding-right",@"padding-bottom",]) {
            PDCSSCSSComputedStyleProperty *property = [[PDCSSCSSComputedStyleProperty alloc] init];
            property.name = zeros;
            property.value = @"";
            inlineStyle.cssProperties = [inlineStyle.cssProperties arrayByAddingObject:property];
        }
        callback(inlineStyle.cssProperties, nil);
    }];
}

@end
