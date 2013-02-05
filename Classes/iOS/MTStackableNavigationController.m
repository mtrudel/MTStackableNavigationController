//
//  MTStackableNavigationController.m
//
//  Created by Mat Trudel on 2013-02-05.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import <objc/runtime.h>

#import "MTStackableNavigationController.h"

static void * const kStackableNavigationControllerStorageKey = (void*)&kStackableNavigationControllerStorageKey;

@interface UIViewController (MTStackableNavigationControllerWriter)
- (void)setStackableNavigationController:(MTStackableNavigationController *)stackableNavigationController;
@end

@implementation UIViewController (MTStackableNavigationController)

- (MTStackableNavigationController *)stackableNavigationController {
  return objc_getAssociatedObject(self, kStackableNavigationControllerStorageKey);
}

- (void)setStackableNavigationController:(MTStackableNavigationController *)stackableNavigationController {
  objc_setAssociatedObject(self, kStackableNavigationControllerStorageKey, stackableNavigationController, OBJC_ASSOCIATION_RETAIN);
}

@end


@implementation MTStackableNavigationController

#pragma mark - Public access methods

- (NSArray *)viewControllers {
  return [self.childViewControllers copy];
}

- (UIViewController *)topViewController {
  return [self.childViewControllers lastObject];
}

- (id)initWithRootViewController:(UIViewController *)rootViewController {
  if (self = [super initWithNibName:nil bundle:nil]) {
    [self pushViewController:rootViewController animated:NO];
  }
  return self;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
  [self addChildViewController:viewController];
  [viewController setStackableNavigationController:self];
  [self.view addSubview:[self containerViewForController:viewController]];
  [viewController didMoveToParentViewController:self];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
  UIViewController *oldController = self.topViewController;
  [oldController willMoveToParentViewController:nil];
  [oldController.view removeFromSuperview];
  [oldController setStackableNavigationController:nil];
  [oldController removeFromParentViewController];
  return oldController;
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
@end
