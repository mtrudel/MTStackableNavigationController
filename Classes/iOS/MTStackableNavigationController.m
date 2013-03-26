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
#import "NSArray+MTCollectionOperators.h"

#define kAnimationDuration 0.3
#define kCoveredControllerWidthDivisor 2
#define kContainerViewShadowWidth 8
#define kPanGesturePercentageToInducePop 0.5

typedef enum {
  MTPop,
  MTPush,
  MTReveal
} MTEventType;

@interface MTStackableNavigationController () <UIGestureRecognizerDelegate>
@property(nonatomic) BOOL isRevealing;
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
  [self updateViewControllerHierarchyForEventType:MTPush withPendingRemovals:nil animated:NO];
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
  if (!self.isRevealing) {
    [self addViewControllerToHierarchy:viewController];
    [self updateViewControllerHierarchyForEventType:MTPush withPendingRemovals:nil animated:animated];
  }
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
  return [self popToViewController:[self ancestorViewControllerTo:self.topViewController] animated:animated][0];
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
  return [self popToViewController:self.childViewControllers[0] animated:animated];
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
  NSUInteger index = [self.childViewControllers indexOfObject:viewController];
  if (!self.isRevealing && index != NSNotFound && index < self.childViewControllers.count - 1) {
    NSArray *toRemove = [self.childViewControllers subarrayWithRange:NSMakeRange(index + 1, self.childViewControllers.count - index - 1)];
    [toRemove makeObjectsPerformSelector:@selector(willMoveToParentViewController:) withObject:nil];
    [self updateViewControllerHierarchyForEventType:MTPop withPendingRemovals:toRemove animated:animated];
    return toRemove;
  } else {
    return nil;
  }
}

#pragma mark - Custom view controller hierarchy manipulation methods

- (void)revealParentControllerAnimated:(BOOL)animated {
  if ([self ancestorViewControllerTo:self.topViewController]) {
    self.isRevealing = YES;
    [self updateViewControllerHierarchyForEventType:MTReveal withPendingRemovals:nil animated:animated];
  }
}

- (void)endRevealAnimated:(BOOL)animated {
  self.isRevealing = NO;
  [self updateViewControllerHierarchyForEventType:MTPush withPendingRemovals:nil animated:animated];
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
  NSArray *viewControllers = [self.childViewControllers subtractValuesIn:pendingRemovals];
  if (self.isRevealing) {
    return @[[self ancestorViewControllerTo:[viewControllers lastObject]], [viewControllers lastObject]];
  } else {
    if ([[[self ancestorViewControllerTo:[viewControllers lastObject]] stackableNavigationItem] leftPeek] != 0) {
      return @[[self ancestorViewControllerTo:[viewControllers lastObject]], [viewControllers lastObject]];
    } else {
      return @[[viewControllers lastObject]];
    }
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

- (void)updateViewControllerHierarchyForEventType:(MTEventType)type withPendingRemovals:(NSArray *)pendingRemovals animated:(BOOL)animated {
  if (self.isViewLoaded) {
    NSArray *expectedHierarchy = [self expectedVisibleViewControllersWithPendingRemovals:pendingRemovals];
    NSArray *currentHierarchy = [self currentlyVisibleViewControllers];
    NSArray *toRemove = [currentHierarchy subtractValuesIn:expectedHierarchy];
    NSArray *toUpdate = [currentHierarchy subtractValuesIn:toRemove];
    NSArray *toInsert = [expectedHierarchy subtractValuesIn:currentHierarchy];

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
    [self updateViewHierarchyTo:expectedHierarchy viaEventType:type byAdding:toInsert removing:toRemove updating:toUpdate animated:animated completion:^{
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

- (void)updateViewHierarchyTo:(NSArray*)expectedHierarchy viaEventType:(MTEventType)type byAdding:(NSArray *)toInsert removing:(NSArray *)toRemove updating:(NSArray *)toUpdate animated:(BOOL)animated completion:(void (^)())completion {
  if (animated && self.view.window) {
    if (toInsert.count > 0) {
      [self ensureContainerViewExistsForControllers:toInsert];
      [self layoutViewControllersToPreanimationStateImmediate:toInsert isPush:type == MTPush];
      [self addViewControllersToViewHierarchyImmediate:toInsert];
    }
    [UIView animateWithDuration:kAnimationDuration animations:^{
      [self layoutViewControllersToFinalStateForRemovalImmediate:toRemove isPush:type == MTPush];
      [self layoutViewControllersToFinalStateImmediate:expectedHierarchy isReveal:type == MTReveal];
      [self addGestureRecognizersToViews:expectedHierarchy isReveal:type == MTReveal];
    } completion:^(BOOL finished) {
      [self removeViewControllersFromViewHierarchyImmediate:toRemove];
      completion();
    }];
  } else {
    [self ensureContainerViewExistsForControllers:toInsert];
    [self layoutViewControllersToFinalStateImmediate:expectedHierarchy isReveal:type == MTReveal];
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

- (void)layoutViewControllersToFinalStateImmediate:(NSArray *)toLayout isReveal:(BOOL)isReveal {
  for (UIViewController *viewController in toLayout) {
    if (isReveal) {
      if (viewController == [toLayout lastObject]) {
        CGFloat peek = viewController.stackableNavigationItem.rightPeek;
        CGRect newFrame = viewController.stackableNavigationItem.containerView.frame;
        newFrame.origin.x = self.view.bounds.size.width - peek;
        viewController.stackableNavigationItem.containerView.frame = newFrame;
      } else {
        CGRect newFrame = viewController.stackableNavigationItem.containerView.frame;
        newFrame.origin.x = 0;
        viewController.stackableNavigationItem.containerView.frame = newFrame;
      }
    } else {
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
    navBar.barStyle = viewController.stackableNavigationItem.barStyle;
    navBar.tintColor = viewController.stackableNavigationItem.tintColor;
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
    viewController.stackableNavigationItem.containerView.layer.shadowRadius = kContainerViewShadowWidth / 2;
    viewController.stackableNavigationItem.containerView.layer.shadowOpacity = 0.3;
    viewController.stackableNavigationItem.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:viewController.stackableNavigationItem.containerView.bounds].CGPath;
  }
}

#pragma mark -- Gesture management

- (void)addGestureRecognizersToViews:(NSArray *)viewControllers isReveal:(BOOL)isReveal {
  for (UIViewController *viewController in viewControllers) {
    for (UIGestureRecognizer *gestureRecognizer in [viewController.stackableNavigationItem.containerView.gestureRecognizers copy]) {
      [viewController.stackableNavigationItem.containerView removeGestureRecognizer:gestureRecognizer];
    }
    if (viewController == [viewControllers lastObject]) {
      for (UIView *view in viewController.stackableNavigationItem.containerView.subviews) {
        view.userInteractionEnabled = !isReveal;
      }
      if (viewController.stackableNavigationItem.shouldRecognizePans && ([self ancestorViewControllerTo:viewController].stackableNavigationItem.leftPeek > 0 || isReveal)) {
        UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidPan:)];
        gestureRecognizer.delegate = self;
        [viewController.stackableNavigationItem.containerView addGestureRecognizer:gestureRecognizer];
      }
      if (isReveal && viewController.stackableNavigationItem.shouldEndRevealOnTapWhenRevealing) {
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidTap:)];
        [viewController.stackableNavigationItem.containerView addGestureRecognizer:gestureRecognizer];
      }
    } else if (!isReveal && viewController.stackableNavigationItem.shouldPopOnTapWhenPeeking) {
      for (UIView *view in viewController.stackableNavigationItem.containerView.subviews) {
        view.userInteractionEnabled = NO;
      }
      UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidTap:)];
      [viewController.stackableNavigationItem.containerView addGestureRecognizer:gestureRecognizer];
    } else if (isReveal) {
      for (UIView *view in viewController.stackableNavigationItem.containerView.subviews) {
        view.userInteractionEnabled = YES;
      }
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
    if (self.isRevealing) {
      if (pannedViewController.stackableNavigationItem.shouldEndRevealWhenPannedToLeft && [gestureRecognizer translationInView:self.view].x <= - [sender view].frame.size.width * (kPanGesturePercentageToInducePop)) {
        [self endRevealAnimated:YES];
      } else {
        CGFloat peek = pannedViewController.stackableNavigationItem.rightPeek;
        CGRect finalFrame = pannedViewController.stackableNavigationItem.containerView.frame;
        finalFrame.origin.x =  self.view.bounds.size.width - peek;
        [UIView animateWithDuration:0.3 animations:^{
          pannedViewController.stackableNavigationItem.containerView.frame = finalFrame;
        }];
      }
    } else {
      if (pannedViewController.stackableNavigationItem.shouldPopWhenPannedToRight && [gestureRecognizer translationInView:self.view].x >= [sender view].frame.size.width * kPanGesturePercentageToInducePop) {
        [self popToViewController:[self ancestorViewControllerTo:pannedViewController] animated:YES];
      } else {
        CGRect finalFrame = pannedViewController.stackableNavigationItem.containerView.frame;
        finalFrame.origin.x = [self ancestorViewControllerTo:pannedViewController].stackableNavigationItem.leftPeek;
        [UIView animateWithDuration:0.3 animations:^{
          pannedViewController.stackableNavigationItem.containerView.frame = finalFrame;
        }];
      }
    }
  } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
    if (self.isRevealing) {
      CGRect finalFrame = pannedViewController.stackableNavigationItem.containerView.frame;
      CGFloat peek = pannedViewController.stackableNavigationItem.rightPeek;
      finalFrame.origin.x = self.view.bounds.size.width - peek + [gestureRecognizer translationInView:self.view].x;
      [UIView animateWithDuration:0.1 animations:^{
        pannedViewController.stackableNavigationItem.containerView.frame = finalFrame;
      }];
    } else {
      CGRect finalFrame = pannedViewController.stackableNavigationItem.containerView.frame;
      finalFrame.origin.x = [self ancestorViewControllerTo:pannedViewController].stackableNavigationItem.leftPeek + MAX([gestureRecognizer translationInView:self.view].x, 0);
      [UIView animateWithDuration:0.1 animations:^{
        pannedViewController.stackableNavigationItem.containerView.frame = finalFrame;
      }];
    }
  }
}

- (void)viewDidTap:(id)sender {
  UITapGestureRecognizer *gestureRecognizer = sender;
  if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
    UIViewController *viewController = self.childViewControllers[[self.childViewControllers indexOfObjectPassingTest:^BOOL(UIViewController *cur, NSUInteger idx, BOOL *stop) {
      return cur.stackableNavigationItem.containerView == [sender view];
    }]];
    if (self.isRevealing) {
      [self endRevealAnimated:YES];
    } else {
      [self popToViewController:viewController animated:YES];
    }
  }
}

#pragma mark - Delegate methods

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
  [self popViewControllerAnimated:YES];
  return NO;
}

@end
