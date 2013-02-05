//
//  MTStackableNavigationPushSegue.m
//
//  Created by Mat Trudel on 2013-02-05.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import "MTStackableNavigationPushSegue.h"

#import "MTStackableNavigationController.h"

@implementation MTStackableNavigationPushSegue

- (void)perform {
  [[self.sourceViewController stackableNavigationController] pushViewController:self.destinationViewController animated:YES];
}

@end
