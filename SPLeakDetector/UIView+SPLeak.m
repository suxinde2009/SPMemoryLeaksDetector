//
//  UIView+SPLeak.m
//  SPLeakDetector
//
//  Created by SuXinDe on 2018/5/30.
//  Copyright © 2018年 su xinde. All rights reserved.
//

#import "UIView+SPLeak.h"
#import <objc/runtime.h>
#import "NSObject+SPLeak.h"

@implementation UIView (SPLeak)

+ (void)prepareForSniffer {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleSEL:@selector(didMoveToSuperview)
                 withSEL:@selector(swizzled_didMoveToSuperview)];
    });
}

- (void)swizzled_didMoveToSuperview {
    [self swizzled_didMoveToSuperview];
    
    BOOL hasAliveParent = false;
    
    UIResponder* r = self.nextResponder;
    while (r) {
        if ([r pProxy] != nil) {
            hasAliveParent = true;
            break;
        }
        r = r.nextResponder;
    }
    
    if (hasAliveParent) {
        [self markAlive];
    }
}

- (BOOL)isAlive {
    BOOL alive = true;
    
    BOOL onUIStack = false;
    
    UIView* v = self;
    while (v.superview != nil) {
        v = v.superview;
    }
    if ([v isKindOfClass:[UIWindow class]]) {
        onUIStack = true;
    }
    
    //save responder
    if (self.pProxy.weakResponder == nil) {
        UIResponder* r = self.nextResponder;
        while (r) {
            if (r.nextResponder == nil) {
                break;
            } else {
                r = r.nextResponder;
            }
            
            if ([r isKindOfClass:[UIViewController class]]) {
                break;
            }
        }
        self.pProxy.weakResponder = r;
    }
    
    
    if (onUIStack == false) {
        alive = false;
        //if controller is active, view should be considered alive too
        if ([self.pProxy.weakResponder isKindOfClass:[UIViewController class]]) {
            alive = true;
        } else {
            //no active controller found
            //            SPLeakLog(@"dangling object: %@", [self class]);
        }
    }
    
    if (alive == false) {
        //        SPLeakLog(@"leaked object: %@ ?", [self class]);
    }
    return alive;
}


@end
