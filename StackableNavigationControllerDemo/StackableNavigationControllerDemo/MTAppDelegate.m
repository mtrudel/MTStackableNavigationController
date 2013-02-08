//
//  MTAppDelegate.m
//  StackableNavigationControllerDemo
//
//  Created by Mat Trudel on 2013-02-07.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import "MTAppDelegate.h"

#import "MTCountingViewController.h"
#import "MTStackableNavigationController.h"

@interface MTAppDelegate () <MTStackableNavigationControllerDelegate, UINavigationControllerDelegate>

@end
@implementation MTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

  UIViewController *viewController = [[MTCountingViewController alloc] initWithNumber:0];

  /*
   Uncomment whichever controller you wish to use -- the semantics within the 
   contained controllers are nearly identical (the only change is the property
   name used to access the containing controller)
  */

//  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
  MTStackableNavigationController *navigationController = [[MTStackableNavigationController alloc] initWithRootViewController:viewController];
  navigationController.delegate = self;

  self.window.rootViewController = navigationController;
  [self.window makeKeyAndVisible];
  return YES;
}

- (void)stackableNavigationController:(MTStackableNavigationController *)stackableNavigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  NSLog(@"delegate received willShow");
}

- (void)stackableNavigationController:(MTStackableNavigationController *)stackableNavigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  NSLog(@"delegate received didShow");
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  NSLog(@"delegate received willShow");
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  NSLog(@"delegate received didShow");
}

@end
