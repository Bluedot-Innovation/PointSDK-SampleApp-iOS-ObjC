//
//  UIWindow+BDVisible.m
//  BDPoint
//
//  Created by Jason Xie on 29/9/16.
//  Copyright © 2016 Bluedot. All rights reserved.
//

#import "UIWindow+BDVisible.h"

@implementation UIWindow (BDVisible)

- (UIViewController *)visibleViewController {
    UIViewController *rootViewController = self.rootViewController;
    return [UIWindow getVisibleViewControllerFrom: rootViewController];
}

+ (UIViewController *) getVisibleViewControllerFrom:(UIViewController *) viewController {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        return [UIWindow getVisibleViewControllerFrom: [((UINavigationController *) viewController) visibleViewController]];
    } else if ([viewController isKindOfClass:[UITabBarController class]]) {
        return [UIWindow getVisibleViewControllerFrom:[((UITabBarController *) viewController) selectedViewController]];
    } else {
        if (viewController.presentedViewController) {
            return [UIWindow getVisibleViewControllerFrom: viewController.presentedViewController];
        } else {
            return viewController;
        }
    }
}

@end
