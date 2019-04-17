//
//  PDCSSDomainController.h
//  YAInspector
//
//  Created by HUANG,Shaojun on 7/17/16.
//  Copyright © 2016 yidian. All rights reserved.
//

#import "PonyDebugger.h"
#import "PDCSSDomain.h"

@interface PDCSSDomainController : PDDomainController<PDCSSCommandDelegate>

+ (PDCSSDomainController *)defaultInstance;
- (void)enable;

@property (nonatomic, strong) PDCSSDomain *domain;

@end
