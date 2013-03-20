//
//  MTStackableNavigationController.h
//
//  Created by Mat Trudel on 2013-02-05.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+MTStackableNavigationController.h"
#import "MTStackableNavigationItem.h"

@protocol MTStackableNavigationControllerDelegate;

@interface MTStackableNavigationController : UIViewController
@property(nonatomic, readonly) BOOL isRevealing;
@property(nonatomic, readonly) NSArray *viewControllers;
@property(nonatomic, readonly) UIViewController *topViewController;
@property(nonatomic, assign) id<MTStackableNavigationControllerDelegate> delegate;

- (id)initWithRootViewController:(UIViewController *)rootViewController;
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (UIViewController *)popViewControllerAnimated:(BOOL)animated;
- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated;

- (void)revealParentControllerAnimated:(BOOL)animated;
- (void)endRevealAnimated:(BOOL)animated;

@end


@protocol MTStackableNavigationControllerDelegate <NSObject>

@optional

- (void)stackableNavigationController:(MTStackableNavigationController *)stackableNavigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)stackableNavigationController:(MTStackableNavigationController *)stackableNavigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end
