//
//  PDDOMStorageDomainController.h
//  PonyDebugger
//
//  Created by huangshaojun on 7/12/16.
//  Copyright © 2016 yidian. All rights reserved.
//

#import "PDDOMStorageDomain.h"
#import "PDDomainController.h"
#import "PDDOMStorageTypes.h"

@interface PDDOMStorageDomainController : PDDomainController<PDDOMStorageCommandDelegate, PDDOMStorageCommandDelegate>

+ (instancetype)defaultInstance;
- (void)enable;

@end
