//
//  MTStackableNavigationController.m
//
//  Created by Mat Trudel on 2013-02-05.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import "MTStackableNavigationController.h"

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
  viewController.view.frame = self.view.bounds;
  [self.view addSubview:viewController.view];
  [viewController didMoveToParentViewController:self];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
  UIViewController *oldController = self.topViewController;
  [oldController willMoveToParentViewController:nil];
  [oldController.view removeFromSuperview];
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

@end
