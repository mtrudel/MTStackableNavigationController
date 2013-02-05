//
//  MTStackableNavigationPushSegue.m
//  Pods
//
//  Created by Mat Trudel on 2013-02-05.
//
//

#import "MTStackableNavigationPushSegue.h"

#import "MTStackableNavigationController.h"

@implementation MTStackableNavigationPushSegue

- (void)perform {
  [[self.sourceViewController stackableNavigationController] pushViewController:self.destinationViewController animated:YES];
}

@end
