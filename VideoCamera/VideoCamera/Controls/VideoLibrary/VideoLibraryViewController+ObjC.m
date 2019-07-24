//
//  VideoLibraryViewController+ObjC.m
//  VideoCamera
//
//  Created by jimmy on 2019/7/24.
//  Copyright © 2019 huangsj. All rights reserved.
//

#import "VideoCamera-Swift.h"

@implementation VideoLibraryViewController (ObjC)

- (void)video: (NSString *) videoPath didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo {
    NSLog(@"%@", error);
    if(error != nil)
        self.saveSelectedErrors = [self.saveSelectedErrors arrayByAddingObject:error];
}

@end
