//
//  UIViewController+MTStackableNavigationController.m
//
//  Created by Mat Trudel on 2013-02-05.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import <objc/runtime.h>

#import "UIViewController+MTStackableNavigationController.h"
#import "MTStackableNavigationItem.h"

static void * const kStackableNavigationControllerStorageKey = (void*)&kStackableNavigationControllerStorageKey;
static void * const kStackableNavigationItemStorageKey = (void*)&kStackableNavigationItemStorageKey;

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
  objc_setAssociatedObject(self, kStackableNavigationControllerStorageKey, stackableNavigationController, OBJC_ASSOCIATION_ASSIGN);
}

- (MTStackableNavigationItem *)stackableNavigationItem {
  MTStackableNavigationItem *result = objc_getAssociatedObject(self, kStackableNavigationItemStorageKey);
  if (!result) {
    result = [[MTStackableNavigationItem alloc] init];
    objc_setAssociatedObject(self, kStackableNavigationItemStorageKey, result, OBJC_ASSOCIATION_RETAIN);
  }
  return result;
}

@end