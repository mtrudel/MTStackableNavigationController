//
//  UIViewController+MTStackedNavigationController.m
//
//  Created by Mat Trudel on 2013-02-05.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import <objc/runtime.h>

#import "UIViewController+MTStackedNavigationController.h"


static void * const kStackableNavigationControllerStorageKey = (void*)&kStackableNavigationControllerStorageKey;

@implementation UIViewController (MTStackedNavigationController)

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