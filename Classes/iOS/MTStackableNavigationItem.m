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
    self.shouldPopOnTapWhenPeeking = YES;
    self.shouldRecognizePans = YES;
    self.shouldPopWhenPannedToRight = YES;
  }
  return self;
}

@end
