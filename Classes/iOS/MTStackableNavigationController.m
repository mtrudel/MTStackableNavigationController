//
//  MTStackableNavigationController.m
//
//  Created by Mat Trudel on 2013-02-05.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "MTStackableNavigationController.h"
#import "MTStackableNavigationItem.h"
#import "UIViewController+MTStackableNavigationController.h"
#import "UIViewController+MTStackableNavigationController_Protected.h"

#define kPushAnimationDuration 0.3
#define kPopAnimationDuration 0.3
#define kCoveredControllerWidthDivisor 4
#define kContainerViewShadowWidth 15

@implementation MTStackableNavigationController

- (id)initWithRootViewController:(UIViewController *)rootViewController {
  if (self = [super initWithNibName:nil bundle:nil]) {
    [self pushViewController:rootViewController animated:NO];
  }
  return self;
}

#pragma mark - Public access methods

- (NSArray *)viewControllers {
  return [self.childViewControllers copy];
}

- (UIViewController *)topViewController {
  return [self.childViewControllers lastObject];
}

#pragma mark - view controller hieracrchy manipulation methods (mirroring UINavigationController)

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
  UIViewController *currentController = self.topViewController;
  [viewController willMoveToParentViewController:self];
  [self addChildViewController:viewController];
  [viewController setStackableNavigationController:self];
  [viewController beginAppearanceTransition:YES animated:animated];
  UIView *newContainerView = [self containerViewForController:viewController previousController:currentController];
  if (animated) {
    CGRect newContainerFinalFrame = newContainerView.frame;
    newContainerView.frame = CGRectOffset(newContainerView.frame, newContainerView.frame.size.width + kContainerViewShadowWidth, 0);
    [self addShadowToView:newContainerView];
    [self.view addSubview:newContainerView];
    [UIView animateWithDuration:kPushAnimationDuration animations:^{
      newContainerView.frame = newContainerFinalFrame;
      if (currentController.stackableNavigationItem.leftPeek == 0) {
        currentController.view.superview.frame = CGRectOffset(currentController.view.superview.frame, -self.view.bounds.size.width / kCoveredControllerWidthDivisor, 0);;
      }
    } completion:^(BOOL finished) {
      if (currentController.stackableNavigationItem.leftPeek == 0) {
        [self removeShadowFromView:newContainerView];
      }
    }];
  } else {
    if (currentController.stackableNavigationItem.leftPeek != 0) {
      [self addShadowToView:newContainerView];
    }
    [self.view addSubview:newContainerView];
  }
  [viewController endAppearanceTransition];
  [viewController didMoveToParentViewController:self];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
  if (self.childViewControllers.count > 1) {
    UIViewController *currentController = self.topViewController;
    [currentController willMoveToParentViewController:nil];
    [currentController beginAppearanceTransition:NO animated:animated];
    if (animated) {
      [self addShadowToView:currentController.view.superview];
      [UIView animateWithDuration:kPopAnimationDuration animations:^{
        currentController.view.superview.frame = CGRectOffset(currentController.view.superview.frame, self.view.bounds.size.width + kContainerViewShadowWidth, 0);

        UIViewController *revealedController = self.childViewControllers[self.childViewControllers.count - 2];

        if (revealedController.stackableNavigationItem.leftPeek == 0) {
          revealedController.view.superview.frame = CGRectOffset(revealedController.view.superview.frame, self.view.bounds.size.width / kCoveredControllerWidthDivisor, 0);
        }

      } completion:^(BOOL finished) {
        [self handleControllerRemoval:currentController];
      }];
    } else {
      [self handleControllerRemoval:currentController];
    }
    return currentController;
  } else {
    return nil;
  }
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
  if ([self.childViewControllers containsObject:viewController]) {
    NSMutableArray *popped = [NSMutableArray array];
    while (self.topViewController != viewController) {
      [popped insertObject:[self popViewControllerAnimated:animated] atIndex:0];
    }
  } else {
    return nil; // TODO -- test this for compat with UINC
  }
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
  return [self popToViewController:self.childViewControllers[0] animated:animated];
}

#pragma mark - Private methods

- (UIView *)containerViewForController:(UIViewController *)viewController previousController:(UIViewController *)previousViewController {
  CGRect rect = UIEdgeInsetsInsetRect(self.view.bounds, UIEdgeInsetsMake(0, previousViewController.stackableNavigationItem.leftPeek, 0, 0));
  UIView *containerView = [[UIView alloc] initWithFrame:rect];
  CGRect navBarFrame, contentFrame;
  CGRectDivide(containerView.bounds, &navBarFrame, &contentFrame, 44, CGRectMinYEdge);

  UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:navBarFrame];

  if (previousViewController.navigationItem) {
    [navBar pushNavigationItem:previousViewController.navigationItem animated:NO];
    navBar.delegate = self;
  }
  
  [navBar pushNavigationItem:viewController.navigationItem animated:NO];
  [containerView addSubview:navBar];
  viewController.view.frame = contentFrame;
  [containerView addSubview:viewController.view];
  return containerView;
}

- (void)addShadowToView:(UIView *)view {
  view.layer.masksToBounds = NO;
  view.layer.shadowOffset = CGSizeMake(-kContainerViewShadowWidth, 0);
  view.layer.shadowRadius = kContainerViewShadowWidth / 5;
  view.layer.shadowOpacity = 0.5;
  view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
}

- (void)removeShadowFromView:(UIView *)view {
  view.layer.masksToBounds = YES;
  view.layer.shadowOpacity = 0;
  view.layer.shadowPath = NULL;
}

- (void)handleControllerRemoval:(UIViewController *)oldController {
  [oldController.view.superview removeFromSuperview];
  [oldController setStackableNavigationController:nil];
  [oldController removeFromParentViewController];
  [oldController endAppearanceTransition];
  [oldController didMoveToParentViewController:nil];
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
  [self popViewControllerAnimated:YES];
  return NO;
}

@end
