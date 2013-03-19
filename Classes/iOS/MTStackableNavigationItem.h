//
//  MTStackableNavigationItem.h
//
//  Created by Mat Trudel on 2013-02-05.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTStackableNavigationItem : NSObject

/**
 * The number of pixels to stay docked on the left when another view is pushed on top
 * Only applies while this is the next-to-top view in the stack
 * Defaults to 0
 */
@property(nonatomic) CGFloat leftPeek;

/**
 * When this view is docked on the left, should a tap on the view cause the
 * stack to pop (revealing this view). Defaults to YES.
 */
@property(nonatomic) BOOL shouldPopOnTapWhenPeeking;

/**
 * If this view is on top of the stack and a view is docked to the left,
 * should this view recognize (and move in response to) pans on this view. 
 * Defaults to YES.
 */
@property(nonatomic) BOOL shouldRecognizePans;

/**
 * Whether this this view should pop itself off the stack if it is panned
 * far enough to the right ('far enough' means more than 50% of the width of
 * this view). Has no effect if shouldRecognizePans is NO. Defaults to YES.
 */
@property(nonatomic) BOOL shouldPopWhenPannedToRight;
@end
