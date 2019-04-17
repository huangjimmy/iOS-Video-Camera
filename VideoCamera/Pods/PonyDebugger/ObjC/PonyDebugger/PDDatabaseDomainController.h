//
//  PDDatabaseDomainController.h
//  PonyDebugger
//
//  Created by HUANG,Shaojun on 7/12/16.
//  Copyright © 2016 yidian. All rights reserved.
//

#import "PDObject.h"
#import "PDDebugger.h"
#import "PDDynamicDebuggerDomain.h"
#import "PDDatabaseDomain.h"
#import "PDDomainController.h"

@interface PDDatabaseDomainController : PDDomainController<PDDatabaseCommandDelegate, PDCommandDelegate>

+ (PDDatabaseDomainController *)defaultInstance;
- (void)enable;

@end
