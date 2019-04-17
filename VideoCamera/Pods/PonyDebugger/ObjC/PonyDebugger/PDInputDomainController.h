//
//  PDInputDomainController.h
//  PonyDebugger
//
//  Created by HUANG,Shaojun on 7/16/16.
//  Copyright © 2016 yidian. All rights reserved.
//

#import "PDDomainController.h"
#import "PDInputDomain.h"

@interface PDInputDomainController : PDDomainController<PDInputCommandDelegate>

+ (PDInputDomainController *)defaultInstance;
- (void)enable;

@end
