//
//  UIViewController+MTStackedNavigationController.h
//
//  Created by Mat Trudel on 2013-02-05.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MTStackableNavigationController;

@interface UIViewController (MTStackedNavigationController)
@property(nonatomic,readonly,retain) MTStackableNavigationController *stackableNavigationController;
@end
