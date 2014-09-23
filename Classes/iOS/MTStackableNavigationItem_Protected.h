//
//  MTStackableNavigationItem_Protected.h
//
//  Created by Mat Trudel on 2013-02-11.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import "MTStackableNavigationItem.h"

@interface MTStackableNavigationItem ()
@property(nonatomic,strong) UIView *containerView;
@property(nonatomic) BOOL appearanceCleanupPending;
@property(nonatomic) BOOL disappearanceCleanupPending;
@property(nonatomic) BOOL willAppearOnPush;
@property(nonatomic, strong) UINavigationBar *navigationBar;
@property(nonatomic, strong) UIToolbar *toolBar;
@property(nonatomic, strong) NSArray *layoutGuideConstraints;
@property(nonatomic, strong) NSLayoutConstraint *leftLayout;
@property(nonatomic, strong) NSLayoutConstraint *rightLayout;
@end