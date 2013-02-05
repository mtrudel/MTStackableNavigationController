//
//  MTStackableNavigationController.h
//
//  Created by Mat Trudel on 2013-02-05.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+MTStackedNavigationController.h"

@interface MTStackableNavigationController : UIViewController
@property(nonatomic, readonly) NSArray *viewControllers;

- (id)initWithRootViewController:(UIViewController *)rootViewController;
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (UIViewController *)popViewControllerAnimated:(BOOL)animated;
- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated;

@property(nonatomic,readonly,retain) UIViewController *topViewController; // The top view controller on the stack.

@end
