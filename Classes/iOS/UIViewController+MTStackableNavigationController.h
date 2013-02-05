//
//  UIViewController+MTStackableNavigationController.h
//
//  Created by Mat Trudel on 2013-02-05.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MTStackableNavigationController;
@class MTStackableNavigationItem;

@interface UIViewController (MTStackableNavigationController)
@property(nonatomic,readonly,strong) MTStackableNavigationController *stackableNavigationController;
@property(nonatomic, strong) MTStackableNavigationItem *stackableNavigationItem;
@end
