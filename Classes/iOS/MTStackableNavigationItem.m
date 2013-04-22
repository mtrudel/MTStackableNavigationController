//
//  MTStackableNavigationItem.m
//
//  Created by Mat Trudel on 2013-02-05.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import "MTStackableNavigationItem_Protected.h"

@implementation MTStackableNavigationItem

- (id)init {
  if (self = [super init]) {
    self.hidesNavigationBar = NO;
    self.barStyle = UIBarStyleDefault;
    self.translucent = NO;
    self.tintColor = nil;
    self.leftPeek = 0;
    self.rightPeek = 20;
    self.shouldPopOnTapWhenPeeking = YES;
    self.shouldEndRevealOnTapWhenRevealing = YES;
    self.shouldRecognizePans = YES;
    self.shouldPopWhenPannedToRight = YES;
    self.shouldEndRevealWhenPannedToLeft = YES;
  }
  return self;
}

@end
