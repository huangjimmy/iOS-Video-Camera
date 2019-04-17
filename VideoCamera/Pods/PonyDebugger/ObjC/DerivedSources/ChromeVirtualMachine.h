//
//  ChromeVirtualMachine.h
//  PonyDebugger
//
//  Created by huangshaojun on 7/13/16.
//  Copyright © 2016 yidian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <UIKit/UIKit.h>

@interface ChromeVirtualMachine : NSObject

@property (nonatomic, strong) JSContext *context;

+ (instancetype)sharedInstance;

- (JSValue*)evaluateScript:(NSString*)script;

@end
