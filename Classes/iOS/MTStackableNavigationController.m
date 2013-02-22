//
//  MTStackableNavigationController.m
//
//  Created by Mat Trudel on 2013-02-05.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "MTStackableNavigationController.h"
#import "MTStackableNavigationItem_Protected.h"
#import "UIViewController+MTStackableNavigationController_Protected.h"

#define kAnimationDuration 0.3
#define kCoveredControllerWidthDivisor 2
#define kContainerViewShadowWidth 15
#define kPanGesturePercentageToInducePop 0.57

@interface MTStackableNavigationController () <UIGestureRecognizerDelegate>
@end

@implementation MTStackableNavigationController

- (id)initWithRootViewController:(UIViewController *)rootViewController {
  if (self = [super initWithNibName:nil bundle:nil]) {
    [self pushViewController:rootViewController animated:NO];
  }
  return self;
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
  return NO;
}

# pragma mark - Lifecycle methods

- (void)viewWillAppear:(BOOL)animated {
  [self updateViewControllerHierarchyWithPendingRemovals:nil animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
  for (UIViewController *viewController in self.childViewControllers) {
    if (viewController.stackableNavigationItem.appearanceCleanupPending) {
      [self postAppearanceViewControllerCleanup:viewController animated:NO];
    }
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  for (UIViewController *viewController in [self currentlyVisibleViewControllers]) {
    [viewController beginAppearanceTransition:NO animated:NO];
    viewController.stackableNavigationItem.disappearanceCleanupPending = YES;
  }
}

- (void)viewDidDisappear:(BOOL)animated {
  for (UIViewController *viewController in self.childViewControllers) {
    if (viewController.stackableNavigationItem.disappearanceCleanupPending) {
      [self postDisappearanceViewControllerCleanup:viewController removeFromViewControllerHierarchy:NO];
    }
  }
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
  [self addViewControllerToHierarchy:viewController];
  [self updateViewControllerHierarchyWithPendingRemovals:nil animated:animated];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
  return [self popToViewController:[self ancestorViewControllerTo:self.topViewController] animated:animated][0];
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
  return [self popToViewController:self.childViewControllers[0] animated:animated];
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
  NSUInteger index = [self.childViewControllers indexOfObject:viewController];
  if (index != NSNotFound && index < self.childViewControllers.count - 1) {
    NSArray *toRemove = [self.childViewControllers subarrayWithRange:NSMakeRange(index + 1, self.childViewControllers.count - index - 1)];
    [toRemove makeObjectsPerformSelector:@selector(willMoveToParentViewController:) withObject:nil];
    [self updateViewControllerHierarchyWithPendingRemovals:toRemove animated:animated];
    return toRemove;
  } else {
    return nil;
  }
}

#pragma mark - View controller hierarchy methods

- (void)addViewControllerToHierarchy:(UIViewController *)viewController {
  [self addChildViewController:viewController];
  [viewController setStackableNavigationController:self];
}

- (UINavigationController *)ancestorViewControllerTo:(UIViewController *)viewController {
  NSUInteger index = [self.childViewControllers indexOfObject:viewController];
  return (index > 0)? self.childViewControllers[index - 1] : nil;
}

- (NSArray *)expectedVisibleViewControllersWithPendingRemovals:(NSArray *)pendingRemovals {
  NSMutableArray *viewControllers = [self.childViewControllers mutableCopy];
  [viewControllers removeObjectsInArray:pendingRemovals];
  if ([[[self ancestorViewControllerTo:[viewControllers lastObject]] stackableNavigationItem] leftPeek] != 0) {
    return @[[self ancestorViewControllerTo:[viewControllers lastObject]], [viewControllers lastObject]];
  } else {
    return @[[viewControllers lastObject]];
  }
}

- (NSArray *)currentlyVisibleViewControllers {
  NSMutableArray *currentlyVisibleViewControllers = [self.childViewControllers mutableCopy];
  [currentlyVisibleViewControllers removeObjectsAtIndexes:[currentlyVisibleViewControllers indexesOfObjectsPassingTest:^BOOL(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
    return !(viewController.isViewLoaded && [viewController.view isDescendantOfView:self.view]);
  }]];
  return currentlyVisibleViewControllers;
}

- (void)postAppearanceViewControllerCleanup:(UIViewController *)viewController animated:(BOOL)animated {
  [viewController endAppearanceTransition];
  [viewController didMoveToParentViewController:self];
  if ([self.delegate respondsToSelector:@selector(stackableNavigationController:didShowViewController:animated:)]) {
    [self.delegate stackableNavigationController:self didShowViewController:viewController animated:animated];
  }
  viewController.stackableNavigationItem.appearanceCleanupPending = NO;
}

- (void)postDisappearanceViewControllerCleanup:(UIViewController *)viewController removeFromViewControllerHierarchy:(BOOL)remove {
  [viewController endAppearanceTransition];
  if (remove) {
    [viewController setStackableNavigationController:nil];
    [viewController removeFromParentViewController];
  }
  viewController.stackableNavigationItem.disappearanceCleanupPending = NO;
}

- (void)updateViewControllerHierarchyWithPendingRemovals:(NSArray *)pendingRemovals animated:(BOOL)animated {
  if (self.isViewLoaded) {
    NSArray *expectedHierarchy = [self expectedVisibleViewControllersWithPendingRemovals:pendingRemovals];
    NSArray *currentHierarchy = [self currentlyVisibleViewControllers];
    NSMutableArray *toRemove = [currentHierarchy mutableCopy];
    [toRemove removeObjectsInArray:expectedHierarchy];
    NSMutableArray *toUpdate = [currentHierarchy mutableCopy];
    [toUpdate removeObjectsInArray:toRemove];
    NSMutableArray *toInsert = [expectedHierarchy mutableCopy];
    [toInsert removeObjectsInArray:currentHierarchy];

    // Load the new views (induce loadView if needed)
    for (UIViewController *viewController in toInsert) {
      [viewController view];
    }
    // Fire the 'willAppear/Disappear' methods
    for (UIViewController *viewController in toRemove) {
      [viewController beginAppearanceTransition:NO animated:animated];
    }
    for (UIViewController *viewController in toInsert) {
      [viewController beginAppearanceTransition:YES animated:animated];
      if ([self.delegate respondsToSelector:@selector(stackableNavigationController:willShowViewController:animated:)]) {
        [self.delegate stackableNavigationController:self willShowViewController:viewController animated:animated];
      }
    }
    // Perform the transition, passing in a cleanup block
    [self updateViewHierarchyTo:expectedHierarchy byAdding:toInsert removing:toRemove updating:toUpdate isPush:(!pendingRemovals) animated:animated completion:^{
      // Fire the 'didAppear/Disappear' methods
      for (UIViewController *viewController in toRemove) {
        [self postDisappearanceViewControllerCleanup:viewController removeFromViewControllerHierarchy:[pendingRemovals containsObject:viewController]];
      }
      for (UIViewController *viewController in toInsert) {
        if (self.view.window) {
          [self postAppearanceViewControllerCleanup:viewController animated:animated];
        } else {
          viewController.stackableNavigationItem.appearanceCleanupPending = YES;
        }
      }
    }];
  }
}

#pragma mark - View management methods

- (void)updateViewHierarchyTo:(NSArray*)expectedHierarchy byAdding:(NSArray *)toInsert removing:(NSArray *)toRemove updating:(NSArray *)toUpdate isPush:(BOOL)isPush animated:(BOOL)animated completion:(void (^)())completion {
  if (animated && self.view.window) {
    [self ensureContainerViewExistsForControllers:toInsert];
    [self layoutViewControllersToPreanimationStateImmediate:toInsert isPush:isPush];
    [self addViewControllersToViewHierarchyImmediate:toInsert];
    [UIView animateWithDuration:kAnimationDuration animations:^{
      [self layoutViewControllersToFinalStateForRemovalImmediate:toRemove isPush:isPush];
      [self layoutViewControllersToFinalStateImmediate:expectedHierarchy];
      [self addGestureRecognizersToViews:expectedHierarchy];
    } completion:^(BOOL finished) {
      [self removeViewControllersFromViewHierarchyImmediate:toRemove];
      completion();
    }];
  } else {
    [self ensureContainerViewExistsForControllers:toInsert];
    [self layoutViewControllersToFinalStateImmediate:expectedHierarchy];
    [self addViewControllersToViewHierarchyImmediate:toInsert];
    [self removeViewControllersFromViewHierarchyImmediate:toRemove];
    completion();
  }
}

- (void)addViewControllersToViewHierarchyImmediate:(NSArray *)toInsert {
  for (UIViewController *viewController in [toInsert reverseObjectEnumerator]) {
    if (viewController == self.topViewController) {
      [self.view addSubview:viewController.stackableNavigationItem.containerView];
    } else if (viewController == [self ancestorViewControllerTo:self.topViewController]) {
      [self.view insertSubview:viewController.stackableNavigationItem.containerView belowSubview:self.topViewController.stackableNavigationItem.containerView];
    } else if (viewController == [self ancestorViewControllerTo:[self ancestorViewControllerTo:self.topViewController]]) {
      [self.view insertSubview:viewController.stackableNavigationItem.containerView belowSubview:[self ancestorViewControllerTo:self.topViewController].stackableNavigationItem.containerView];      
    } else {
      NSAssert(false, @"Don't know what index to add a view controller");
    }
  }
}

- (void)layoutViewControllersToPreanimationStateImmediate:(NSArray *)toLayout isPush:(BOOL)isPush {
  NSAssert(!isPush || [toLayout count] == 1, @"Can't pre-position more than one view controller on a push");
  for (UIViewController *viewController in toLayout) {
    NSAssert(![viewController.stackableNavigationItem.containerView isDescendantOfView:self.view], @"Can't pre-position an already inserted view controller");
    if (isPush) {
      viewController.stackableNavigationItem.containerView.frame = CGRectApplyAffineTransform(viewController.stackableNavigationItem.containerView.frame, CGAffineTransformMakeTranslation(self.view.bounds.size.width + kContainerViewShadowWidth, 0));
    }
  }
}

- (void)layoutViewControllersToFinalStateForRemovalImmediate:(NSArray *)toLayout isPush:(BOOL)isPush {
  for (UIViewController *viewController in toLayout) {
    if (isPush) {
      viewController.stackableNavigationItem.containerView.frame = CGRectApplyAffineTransform(viewController.stackableNavigationItem.containerView.frame, CGAffineTransformMakeTranslation(-viewController.stackableNavigationItem.containerView.frame.size.width / kCoveredControllerWidthDivisor, 0));
    } else {
      viewController.stackableNavigationItem.containerView.frame = CGRectApplyAffineTransform(viewController.stackableNavigationItem.containerView.frame, CGAffineTransformMakeTranslation(self.view.bounds.size.width + kContainerViewShadowWidth, 0));
    }
  }
}

- (void)layoutViewControllersToFinalStateImmediate:(NSArray *)toLayout {
  for (UIViewController *viewController in toLayout) {
    if (viewController == [toLayout lastObject]) {
      CGFloat peek = [self ancestorViewControllerTo:viewController].stackableNavigationItem.leftPeek;
      viewController.stackableNavigationItem.containerView.frame = CGRectMake(peek, 0, self.view.bounds.size.width - peek, self.view.bounds.size.height);
    } else {
      CGRect newFrame = viewController.stackableNavigationItem.containerView.frame;
      newFrame.origin.x = 0;
      viewController.stackableNavigationItem.containerView.frame = newFrame;
    }
  }
}

- (void)removeViewControllersFromViewHierarchyImmediate:(NSArray *)toRemove {
  for (UIViewController *viewController in toRemove) {
    [viewController.stackableNavigationItem.containerView removeFromSuperview];
  }
}

- (void)ensureContainerViewExistsForControllers:(NSArray *)viewControllers {
  for (UIViewController *viewController in viewControllers) {
    [self ensureContainerViewExistsForController:viewController];
  }
}

- (void)ensureContainerViewExistsForController:(UIViewController *)viewController {
  if (!viewController.stackableNavigationItem.containerView) {
    UIViewController *previousViewController = [self ancestorViewControllerTo:viewController];
    CGRect rect = UIEdgeInsetsInsetRect(self.view.bounds, UIEdgeInsetsMake(0, previousViewController.stackableNavigationItem.leftPeek, 0, 0));
    viewController.stackableNavigationItem.containerView = [[UIView alloc] initWithFrame:rect];
    CGRect navBarFrame, contentFrame, toolbarFrame;
    CGRectDivide(viewController.stackableNavigationItem.containerView.bounds, &navBarFrame, &contentFrame, 44, CGRectMinYEdge);
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:navBarFrame];
    if (previousViewController.navigationItem) {
      UINavigationItem *previousItem = [[UINavigationItem alloc] initWithTitle:previousViewController.navigationItem.title];
      previousItem.backBarButtonItem = previousViewController.navigationItem.backBarButtonItem;
      [navBar pushNavigationItem:previousItem animated:NO];
      navBar.delegate = self;
    }
    [navBar pushNavigationItem:viewController.navigationItem animated:NO];
    [viewController.stackableNavigationItem.containerView addSubview:navBar];

    if (viewController.toolbarItems) {
      CGRectDivide(contentFrame, &toolbarFrame, &contentFrame, 44, CGRectMaxYEdge);
      UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:toolbarFrame];
      toolbar.items = viewController.toolbarItems;
      [viewController.stackableNavigationItem.containerView addSubview:toolbar];
    }
    viewController.view.frame = contentFrame;
    [viewController.stackableNavigationItem.containerView addSubview:viewController.view];

    viewController.stackableNavigationItem.containerView.layer.masksToBounds = NO;
    viewController.stackableNavigationItem.containerView.layer.shadowOffset = CGSizeMake(-kContainerViewShadowWidth, 0);
    viewController.stackableNavigationItem.containerView.layer.shadowRadius = kContainerViewShadowWidth / 5;
    viewController.stackableNavigationItem.containerView.layer.shadowOpacity = 0.5;
    viewController.stackableNavigationItem.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:viewController.stackableNavigationItem.containerView.bounds].CGPath;
  }
}

#pragma mark -- Gesture management

- (void)addGestureRecognizersToViews:(NSArray *)viewControllers {
  for (UIViewController *viewController in viewControllers) {
    for (UIGestureRecognizer *gestureRecognizer in [viewController.stackableNavigationItem.containerView.gestureRecognizers copy]) {
      [viewController.stackableNavigationItem.containerView removeGestureRecognizer:gestureRecognizer];
    }
    if (viewController == [viewControllers lastObject]) {
      if (viewController.stackableNavigationItem.shouldRecognizePans && [self ancestorViewControllerTo:viewController].stackableNavigationItem.leftPeek > 0) {
        UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidPan:)];
        gestureRecognizer.delegate = self;
        [viewController.stackableNavigationItem.containerView addGestureRecognizer:gestureRecognizer];
      }
    } else if (viewController.stackableNavigationItem.shouldPopOnTapWhenPeeking) {
      UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidTap:)];
      [viewController.stackableNavigationItem.containerView addGestureRecognizer:gestureRecognizer];
    }
  }
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  static Class reorderControlClass;
  if (!reorderControlClass) {
    reorderControlClass = NSClassFromString(@"UITableViewCellReorderControl");
  }
  return ![touch.view isKindOfClass:[UISlider class]] && ![touch.view isKindOfClass:reorderControlClass];
}

- (void)viewDidPan:(id)sender {
  UIPanGestureRecognizer *gestureRecognizer = sender;
  UIViewController *pannedViewController = self.childViewControllers[[self.childViewControllers indexOfObjectPassingTest:^BOOL(UIViewController *cur, NSUInteger idx, BOOL *stop) {
    return cur.stackableNavigationItem.containerView == [sender view];
  }]];

  if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
    if (pannedViewController.stackableNavigationItem.shouldPopWhenPannedToRight && [gestureRecognizer translationInView:self.view].x >= [sender view].frame.size.width * kPanGesturePercentageToInducePop) {
      [self popToViewController:[self ancestorViewControllerTo:pannedViewController] animated:YES];
    } else {
      CGRect finalFrame = pannedViewController.stackableNavigationItem.containerView.frame;
      finalFrame.origin.x = [self ancestorViewControllerTo:pannedViewController].stackableNavigationItem.leftPeek;
      [UIView animateWithDuration:0.3 animations:^{
        pannedViewController.stackableNavigationItem.containerView.frame = finalFrame;
      }];
    }
  } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
    CGRect finalFrame = pannedViewController.stackableNavigationItem.containerView.frame;
    finalFrame.origin.x = [self ancestorViewControllerTo:pannedViewController].stackableNavigationItem.leftPeek + MAX([gestureRecognizer translationInView:self.view].x, 0);
    [UIView animateWithDuration:0.1 animations:^{
      pannedViewController.stackableNavigationItem.containerView.frame = finalFrame;
    }];
  }
}

- (void)viewDidTap:(id)sender {
  UIViewController *viewController = self.childViewControllers[[self.childViewControllers indexOfObjectPassingTest:^BOOL(UIViewController *cur, NSUInteger idx, BOOL *stop) {
    return cur.stackableNavigationItem.containerView == [sender view];
  }]];
  [self popToViewController:viewController animated:YES];
}

#pragma mark - Delegate methods

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
  [self popViewControllerAnimated:YES];
  return NO;
}


@end
