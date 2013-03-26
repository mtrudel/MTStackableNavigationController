//
//  MTStackableNavigationPushSegue.m
//
//  Created by Mat Trudel on 2013-02-05.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import "MTStackableNavigationPushSegue.h"

#import "MTStackableNavigationController.h"

@implementation MTStackableNavigationPushSegue

- (id)initWithIdentifier:(NSString *)identifier source:(UIViewController *)source destination:(UIViewController *)destination {
  if (self = [super initWithIdentifier:identifier source:source destination:destination]) {
    self.isAnimated = YES;
  }
  return self;
}

- (void)perform {
  [[self.sourceViewController stackableNavigationController] pushViewController:self.destinationViewController animated:self.isAnimated];
}

@end
