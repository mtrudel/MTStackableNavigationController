//
//  MTStackableNavigationController.m
//
//  Created by Mat Trudel on 2013-02-05.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

#import "MTStackableNavigationController.h"

#define kPushAnimationDuration 0.3
#define kPopAnimationDuration 0.3
#define kCoveredControllerWidthDivisor 4
#define kContainerViewShadowWidth 15

static void * const kStackableNavigationControllerStorageKey = (void*)&kStackableNavigationControllerStorageKey;

@interface UIViewController (MTStackableNavigationControllerWriter)
- (void)setStackableNavigationController:(MTStackableNavigationController *)stackableNavigationController;
@end

@implementation UIViewController (MTStackableNavigationController)

- (MTStackableNavigationController *)stackableNavigationController {
  UIViewController *cur = self;
  MTStackableNavigationController *result;
  while (cur != nil && result == nil) {
    result = objc_getAssociatedObject(cur, kStackableNavigationControllerStorageKey);
    cur = cur.parentViewController;
  }
  return result;
}

- (void)setStackableNavigationController:(MTStackableNavigationController *)stackableNavigationController {
  objc_setAssociatedObject(self, kStackableNavigationControllerStorageKey, stackableNavigationController, OBJC_ASSOCIATION_RETAIN);
}

@end


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
  UIView *currentContainerView = self.topViewController.view.superview;

  [viewController willMoveToParentViewController:self];
  [self addChildViewController:viewController];
  [viewController setStackableNavigationController:self];
  [viewController beginAppearanceTransition:YES animated:animated];
  UIView *newContainerView = [self containerViewForController:viewController];
  if (animated) {
    CGRect newContainerFinalFrame = newContainerView.frame;
    CGRect currentContainerFinalFrame = CGRectOffset(currentContainerView.frame, -self.view.bounds.size.width / kCoveredControllerWidthDivisor, 0);
    newContainerView.frame = CGRectOffset(newContainerView.frame, self.view.bounds.size.width + kContainerViewShadowWidth, 0);
    [self addShadowToView:newContainerView];
    [self.view addSubview:newContainerView];
    [UIView animateWithDuration:kPushAnimationDuration animations:^{
      newContainerView.frame = newContainerFinalFrame;
      currentContainerView.frame = currentContainerFinalFrame;
    } completion:^(BOOL finished) {
      [self removeShadowFromView:newContainerView];
    }];
  } else {
    [self.view addSubview:newContainerView];
  }
  [viewController endAppearanceTransition];
  [viewController didMoveToParentViewController:self];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
  if (self.childViewControllers.count > 1) {
    UIViewController *oldController = self.topViewController;
    [oldController willMoveToParentViewController:nil];
    [oldController beginAppearanceTransition:NO animated:animated];
    if (animated) {
      UIViewController *newViewController = self.childViewControllers[self.childViewControllers.count - 2];
      CGRect oldContainerFinalFrame = CGRectOffset(self.topViewController.view.superview.frame, self.view.bounds.size.width + kContainerViewShadowWidth, 0);
      CGRect newContainerFinalFrame = self.view.bounds;
      [self addShadowToView:oldController.view.superview];
      [UIView animateWithDuration:kPopAnimationDuration animations:^{
        oldController.view.superview.frame = oldContainerFinalFrame;
        newViewController.view.superview.frame = newContainerFinalFrame;
      } completion:^(BOOL finished) {
        [self handleControllerRemoval:oldController];
      }];
    } else {
      [self handleControllerRemoval:oldController];
    }
    return oldController;
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

- (UIView *)containerViewForController:(UIViewController *)viewController {
  UIView *containerView = [[UIView alloc] initWithFrame:self.view.bounds];
  CGRect navBarFrame, contentFrame;
  CGRectDivide(self.view.bounds, &navBarFrame, &contentFrame, 44, CGRectMinYEdge);

  UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:navBarFrame];
  [navBar pushNavigationItem:viewController.navigationItem animated:NO];
  [containerView addSubview:navBar];
  viewController.view.frame = contentFrame;
  [containerView addSubview:viewController.view];
  return containerView;
}

- (void)addShadowToView:(UIView *)view {
  view.layer.masksToBounds = NO;
  view.layer.shadowOffset = CGSizeMake(-kContainerViewShadowWidth, kContainerViewShadowWidth * 1.5);
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
@end
