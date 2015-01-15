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
#define kPanGesturePercentageToInducePop 0.5
#define kPanGesturePercentageToEndReveal 0.2
#define kShadowRadius 4.
#define kShadowWidth 8.

typedef enum {
  MTPop,
  MTPush,
  MTReveal
} MTEventType;

@interface MTStackableNavigationController () <UIGestureRecognizerDelegate, UINavigationBarDelegate>
@property(nonatomic) BOOL isRevealing;
@property(nonatomic, strong) UIView *statusBarMask;
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

- (void)viewDidLoad {
  [super viewDidLoad];
  self.statusBarMask = [[UIView alloc] initWithFrame:CGRectZero];
  self.statusBarMask.translatesAutoresizingMaskIntoConstraints = NO;
  self.statusBarMask.backgroundColor = [UIColor whiteColor];
  [self.view insertSubview:self.statusBarMask atIndex:0];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.topLayoutGuide
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.statusBarMask
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1.
                                                         constant:0.]];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.topLayoutGuide
                                                        attribute:NSLayoutAttributeBottom
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.statusBarMask
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.
                                                         constant:0.]];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                        attribute:NSLayoutAttributeLeft
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.statusBarMask
                                                        attribute:NSLayoutAttributeLeft
                                                       multiplier:1.
                                                         constant:0.]];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                        attribute:NSLayoutAttributeRight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.statusBarMask
                                                        attribute:NSLayoutAttributeRight
                                                       multiplier:1.
                                                         constant:0.]];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self updateViewControllerHierarchyForEventType:MTPush withPendingRemovals:nil animated:NO completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  for (UIViewController *viewController in self.childViewControllers) {
    if (viewController.stackableNavigationItem.appearanceCleanupPending) {
      [self postAppearanceViewControllerCleanup:viewController animated:NO];
    }
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  for (UIViewController *viewController in [self currentlyVisibleViewControllers]) {
    [viewController beginAppearanceTransition:NO animated:NO];
    viewController.stackableNavigationItem.disappearanceCleanupPending = YES;
  }
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear: animated];
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
    [self updateViewControllerHierarchyForEventType:MTPush withPendingRemovals:nil animated:animated completion:nil];
  }
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
  return [self popToViewController:[self ancestorViewControllerTo:self.topViewController] animated:animated][0];
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
  return [self popToViewController:self.childViewControllers[0] animated:animated];
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
  self.isRevealing = NO;
  NSUInteger index = [self.childViewControllers indexOfObject:viewController];
  if (!self.isRevealing && index != NSNotFound && index < self.childViewControllers.count - 1) {
    NSArray *toRemove = [self.childViewControllers subarrayWithRange:NSMakeRange(index + 1, self.childViewControllers.count - index - 1)];
    [toRemove makeObjectsPerformSelector:@selector(willMoveToParentViewController:) withObject:nil];
    [self updateViewControllerHierarchyForEventType:MTPop withPendingRemovals:toRemove animated:animated completion:nil];
    return toRemove;
  } else {
    return nil;
  }
}

#pragma mark - Custom view controller hierarchy manipulation methods

- (void)revealParentControllerAnimated:(BOOL)animated {
  if ([self ancestorViewControllerTo:self.topViewController]) {
    self.isRevealing = YES;
    [self updateViewControllerHierarchyForEventType:MTReveal withPendingRemovals:nil animated:animated completion:nil];
  }
}

- (void)endRevealAnimated:(BOOL)animated {
  if (self.isRevealing) {
    self.isRevealing = NO;
    [self updateViewControllerHierarchyForEventType:MTPush withPendingRemovals:nil animated:animated completion:nil];
  }
}

- (void)endRevealByReplacingTopWith:(UIViewController *)controller animated:(BOOL)animated {
  if (self.isRevealing) {
    self.isRevealing = NO;
    [self updateViewControllerHierarchyForEventType:MTPop withPendingRemovals:@[self.topViewController] animated:animated completion:^{
      [self pushViewController:controller animated:animated];
    }];
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

- (void)updateViewControllerHierarchyForEventType:(MTEventType)type withPendingRemovals:(NSArray *)pendingRemovals animated:(BOOL)animated completion:(void (^)())completion {
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
      [self ensureContainerViewExistsForController:viewController];
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
      if (completion) {
        completion();
      }
    }];
  }
}

#pragma mark - View management methods

- (void)updateViewHierarchyTo:(NSArray*)expectedHierarchy viaEventType:(MTEventType)type byAdding:(NSArray *)toInsert removing:(NSArray *)toRemove updating:(NSArray *)toUpdate animated:(BOOL)animated completion:(void (^)())completion {
  if (animated && self.view.window) {
    if (toInsert.count > 0) {
      [self layoutViewControllersToPreanimationStateImmediate:toInsert isPush:type == MTPush];
      [self addViewControllersToViewHierarchyImmediate:toInsert];
      [self addShadowsToViewControllers:toInsert animated:YES];
      [self.view layoutIfNeeded];
    }
    [self removeShadowsFromViewControllers:toRemove animated:YES];
    [UIView animateWithDuration:kAnimationDuration animations:^{
      [self layoutViewControllersToFinalStateForRemovalImmediate:toRemove isPush:type == MTPush];
      [self layoutViewControllersToFinalStateImmediate:expectedHierarchy isReveal:type == MTReveal];
      [self addGestureRecognizersToViews:expectedHierarchy isReveal:type == MTReveal];
      [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
      [self removeViewControllersFromViewHierarchyImmediate:toRemove];
      completion();
    }];
  } else {
    [self addViewControllersToViewHierarchyImmediate:toInsert];
    [self addShadowsToViewControllers:toInsert animated:NO];
    [self layoutViewControllersToFinalStateImmediate:expectedHierarchy isReveal:type == MTReveal];
    [self.view layoutIfNeeded];
    [self removeViewControllersFromViewHierarchyImmediate:toRemove];
    completion();
  }
}

- (void)addViewControllersToViewHierarchyImmediate:(NSArray *)toInsert {
  for (UIViewController *viewController in [toInsert reverseObjectEnumerator]) {
    if (viewController == self.topViewController) {
      [self.view insertSubview:viewController.stackableNavigationItem.containerView belowSubview:self.statusBarMask];
    } else if (viewController == [self ancestorViewControllerTo:self.topViewController]) {
      [self.view insertSubview:viewController.stackableNavigationItem.containerView belowSubview:self.topViewController.stackableNavigationItem.containerView];
    } else if (viewController == [self ancestorViewControllerTo:[self ancestorViewControllerTo:self.topViewController]]) {
      [self.view insertSubview:viewController.stackableNavigationItem.containerView belowSubview:[self ancestorViewControllerTo:self.topViewController].stackableNavigationItem.containerView];
    } else {
      NSAssert(false, @"Don't know what index to add a view controller");
    }

    NSMutableArray *layoutGuideConstraints = [NSMutableArray array];
    if (viewController.stackableNavigationItem.navigationBar) {
      [layoutGuideConstraints addObject:[NSLayoutConstraint constraintWithItem:self.topLayoutGuide
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:viewController.stackableNavigationItem.navigationBar
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.
                                                                      constant:0.]];
    } else {
      [layoutGuideConstraints addObject:[NSLayoutConstraint constraintWithItem:self.topLayoutGuide
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:viewController.topLayoutGuide
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.
                                                                      constant:0.]];
    }
    if (viewController.stackableNavigationItem.toolBar) {
      [layoutGuideConstraints addObject:[NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:viewController.stackableNavigationItem.toolBar
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.
                                                                      constant:0.]];
    } else {
      [layoutGuideConstraints addObject:[NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:viewController.bottomLayoutGuide
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.
                                                                      constant:0.]];
    }
    [layoutGuideConstraints addObject:[NSLayoutConstraint constraintWithItem:self.topLayoutGuide
                                                                   attribute:NSLayoutAttributeBottom
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:viewController.stackableNavigationItem.containerView
                                                                   attribute:NSLayoutAttributeTop
                                                                  multiplier:1.
                                                                    constant:0.]];
    [layoutGuideConstraints addObject:[NSLayoutConstraint constraintWithItem:self.view
                                                                   attribute:NSLayoutAttributeBottom
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:viewController.stackableNavigationItem.containerView
                                                                   attribute:NSLayoutAttributeBottom
                                                                  multiplier:1.
                                                                    constant:0.]];
    viewController.stackableNavigationItem.leftLayout = [NSLayoutConstraint constraintWithItem:viewController.stackableNavigationItem.containerView
                                                                                     attribute:NSLayoutAttributeLeft
                                                                                     relatedBy:NSLayoutRelationEqual
                                                                                        toItem:self.view
                                                                                     attribute:NSLayoutAttributeLeft
                                                                                    multiplier:1.
                                                                                      constant:viewController.stackableNavigationItem.willAppearOnPush? CGRectGetWidth(self.view.frame) : 0];
    [layoutGuideConstraints addObject:viewController.stackableNavigationItem.leftLayout];
    viewController.stackableNavigationItem.rightLayout = [NSLayoutConstraint constraintWithItem:viewController.stackableNavigationItem.containerView
                                                                                      attribute:NSLayoutAttributeRight
                                                                                      relatedBy:NSLayoutRelationEqual
                                                                                         toItem:self.view
                                                                                      attribute:NSLayoutAttributeRight
                                                                                     multiplier:1.
                                                                                      constant:viewController.stackableNavigationItem.willAppearOnPush? CGRectGetWidth(self.view.frame) : 0];
    [layoutGuideConstraints addObject:viewController.stackableNavigationItem.rightLayout];
    viewController.stackableNavigationItem.willAppearOnPush = NO;
    [layoutGuideConstraints setValue:@(UILayoutPriorityRequired) forKey:@"priority"];
    [self.view addConstraints:layoutGuideConstraints];
    viewController.stackableNavigationItem.layoutGuideConstraints = layoutGuideConstraints;
  }
}

- (void)layoutViewControllersToPreanimationStateImmediate:(NSArray *)toLayout isPush:(BOOL)isPush {
  NSAssert(!isPush || [toLayout count] == 1, @"Can't pre-position more than one view controller on a push");
  for (UIViewController *viewController in toLayout) {
    NSAssert(![viewController.stackableNavigationItem.containerView isDescendantOfView:self.view], @"Can't pre-position an already inserted view controller");
    if (isPush) {
      viewController.stackableNavigationItem.willAppearOnPush = YES;
    }
  }
}

- (void)layoutViewControllersToFinalStateForRemovalImmediate:(NSArray *)toLayout isPush:(BOOL)isPush {
  for (UIViewController *viewController in toLayout) {
    if (isPush) {
      viewController.stackableNavigationItem.leftLayout.constant -= viewController.stackableNavigationItem.containerView.frame.size.width / kCoveredControllerWidthDivisor;
      viewController.stackableNavigationItem.rightLayout.constant -= viewController.stackableNavigationItem.containerView.frame.size.width / kCoveredControllerWidthDivisor;
    } else {
      viewController.stackableNavigationItem.leftLayout.constant += CGRectGetWidth(viewController.stackableNavigationItem.containerView.frame);
      viewController.stackableNavigationItem.rightLayout.constant += CGRectGetWidth(viewController.stackableNavigationItem.containerView.frame);
    }
  }
}

- (void)layoutViewControllersToFinalStateImmediate:(NSArray *)toLayout isReveal:(BOOL)isReveal {
  for (UIViewController *viewController in toLayout) {
    if (isReveal) {
      if (viewController == [toLayout lastObject]) {
        CGFloat peek = viewController.stackableNavigationItem.rightPeek;
        viewController.stackableNavigationItem.leftLayout.constant = self.view.bounds.size.width - peek;
        viewController.stackableNavigationItem.rightLayout.constant = self.view.bounds.size.width - peek;
      } else {
        viewController.stackableNavigationItem.leftLayout.constant = 0;
        viewController.stackableNavigationItem.rightLayout.constant = -[[[toLayout lastObject] stackableNavigationItem] rightPeek];

      }
    } else {
      if (viewController == [toLayout lastObject]) {
        CGFloat peek = [self ancestorViewControllerTo:viewController].stackableNavigationItem.leftPeek;
        viewController.stackableNavigationItem.leftLayout.constant = peek;
        viewController.stackableNavigationItem.rightLayout.constant = 0;
      } else {
        viewController.stackableNavigationItem.leftLayout.constant = 0;
        viewController.stackableNavigationItem.rightLayout.constant = 0;
      }
    }
  }
}

- (void)removeViewControllersFromViewHierarchyImmediate:(NSArray *)toRemove {
  for (UIViewController *viewController in toRemove) {
    [viewController.stackableNavigationItem.containerView removeFromSuperview];
    [self.view removeConstraints:viewController.stackableNavigationItem.layoutGuideConstraints];
  }
}

- (void)ensureContainerViewExistsForController:(UIViewController *)viewController {
  if (!viewController.stackableNavigationItem.containerView) {
    UIViewController *previousViewController = [self ancestorViewControllerTo:viewController];

    CGRect containerRect = UIEdgeInsetsInsetRect(self.view.bounds, UIEdgeInsetsMake(0, previousViewController.stackableNavigationItem.leftPeek, 0, 0));
    UIView *containerView = [[UIView alloc] initWithFrame:containerRect];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    containerView.backgroundColor = [UIColor whiteColor];

    // First, insert the navigation bar if needed
    if (!viewController.stackableNavigationItem.hidesNavigationBar) {
      UINavigationBar *navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectZero];
      navigationBar.translatesAutoresizingMaskIntoConstraints = NO;
      viewController.stackableNavigationItem.navigationBar = navigationBar;
      if (viewController.stackableNavigationItem.barStyle != UIBarStyleDefault) {
        navigationBar.barStyle = viewController.stackableNavigationItem.barStyle;
      }
      navigationBar.translucent = viewController.stackableNavigationItem.isTranslucent;
      if (viewController.stackableNavigationItem.tintColor) {
        navigationBar.tintColor = viewController.stackableNavigationItem.tintColor;
      }
      if (previousViewController.navigationItem) {
        UINavigationItem *previousItem = [[UINavigationItem alloc] initWithTitle:previousViewController.navigationItem.title];
        previousItem.backBarButtonItem = previousViewController.navigationItem.backBarButtonItem;
        [navigationBar pushNavigationItem:previousItem animated:NO];
        navigationBar.delegate = self;
      }
      [navigationBar pushNavigationItem:viewController.navigationItem animated:NO];

      CGFloat preferredHeight = [navigationBar intrinsicContentSize].height;
      [containerView addSubview:navigationBar];
      [containerView addConstraint:[NSLayoutConstraint constraintWithItem:navigationBar
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:containerView
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1.
                                                                 constant:0.]];
      [containerView addConstraint:[NSLayoutConstraint constraintWithItem:navigationBar
                                                                attribute:NSLayoutAttributeRight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:containerView
                                                                attribute:NSLayoutAttributeRight
                                                               multiplier:1.
                                                                 constant:0.]];
      [containerView addConstraint:[NSLayoutConstraint constraintWithItem:navigationBar
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.
                                                                 constant:preferredHeight]];
    }

    // Next, insert the toolbar if needed
    if (viewController.toolbarItems) {
      UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
      viewController.stackableNavigationItem.toolBar = toolbar;
      toolbar.translatesAutoresizingMaskIntoConstraints = NO;
      toolbar.items = viewController.toolbarItems;
      CGFloat preferredHeight = [toolbar intrinsicContentSize].height;
      [containerView addSubview:toolbar];
      [containerView addConstraint:[NSLayoutConstraint constraintWithItem:toolbar
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:containerView
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1.
                                                                 constant:0.]];
      [containerView addConstraint:[NSLayoutConstraint constraintWithItem:toolbar
                                                                attribute:NSLayoutAttributeRight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:containerView
                                                                attribute:NSLayoutAttributeRight
                                                               multiplier:1.
                                                                 constant:0.]];
      [containerView addConstraint:[NSLayoutConstraint constraintWithItem:toolbar
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.
                                                                 constant:preferredHeight]];
    }

    // Finally, insert the controller's view
    UIView *view = viewController.view;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view removeConstraints:[view constraints]];
    [containerView insertSubview:view atIndex:0];
    [containerView addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                              attribute:NSLayoutAttributeLeft
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:containerView
                                                              attribute:NSLayoutAttributeLeft
                                                             multiplier:1.
                                                               constant:0.]];
    [containerView addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                              attribute:NSLayoutAttributeRight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:containerView
                                                              attribute:NSLayoutAttributeRight
                                                             multiplier:1.
                                                               constant:0.]];
    if (viewController.stackableNavigationItem.navigationBar) {
      [containerView addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:viewController.stackableNavigationItem.navigationBar
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.
                                                                 constant:0.]];
    } else {
      [containerView addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:containerView
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1.
                                                                 constant:0.]];
    }
    [containerView addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:containerView
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.
                                                               constant:0.]];
    // Last but not least, add the outer container view to the VC's stackableItem
    viewController.stackableNavigationItem.containerView = containerView;
  }
}

#pragma mark -- Shadow management

- (void)addShadowsToViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
  for (UIViewController *viewController in viewControllers) {
    viewController.stackableNavigationItem.containerView.layer.masksToBounds = NO;
    viewController.stackableNavigationItem.containerView.layer.shadowRadius = kShadowRadius;
    viewController.stackableNavigationItem.containerView.layer.shadowOpacity = 0.3;
    viewController.stackableNavigationItem.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:viewController.stackableNavigationItem.containerView.bounds].CGPath;

    if (animated) {
      CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"shadowOffset"];
      animation.duration = kAnimationDuration;
      animation.fromValue = [NSValue valueWithCGSize:CGSizeMake(kShadowRadius, 0)];
      animation.toValue = [NSValue valueWithCGSize:CGSizeMake(-kShadowWidth, 0)];
      [viewController.stackableNavigationItem.containerView.layer addAnimation:animation forKey:nil];
    }
    viewController.stackableNavigationItem.containerView.layer.shadowOffset = CGSizeMake(-kShadowWidth, 0);
  }
}

- (void)removeShadowsFromViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
  for (UIViewController *viewController in viewControllers) {
    if (animated) {
      CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"shadowOffset"];
      animation.duration = kAnimationDuration;
      animation.fromValue = [NSValue valueWithCGSize:viewController.stackableNavigationItem.containerView.layer.shadowOffset];
      animation.toValue = [NSValue valueWithCGSize:CGSizeMake(kShadowRadius, 0)];
      [viewController.stackableNavigationItem.containerView.layer addAnimation:animation forKey:nil];
    }
    viewController.stackableNavigationItem.containerView.layer.shadowOffset = CGSizeMake(kShadowRadius, 0);
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
      if (pannedViewController.stackableNavigationItem.shouldEndRevealWhenPannedToLeft && [gestureRecognizer translationInView:self.view].x <= - [sender view].frame.size.width * (kPanGesturePercentageToEndReveal)) {
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
      finalFrame.origin.x = self.view.bounds.size.width - peek + MIN([gestureRecognizer translationInView:self.view].x, 0);
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
  UINavigationController *popper = [[self.childViewControllers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIViewController *controller, NSDictionary *bindings) {
    return controller.stackableNavigationItem.navigationBar == navigationBar;
  }]] lastObject];
  [self popToViewController:[self ancestorViewControllerTo:popper] animated:YES];
  return NO;
}

@end
