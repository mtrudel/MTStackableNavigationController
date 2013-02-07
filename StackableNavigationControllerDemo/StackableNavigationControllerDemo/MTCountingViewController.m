//
//  MTCountingViewController.m
//  StackableNavigationControllerDemo
//
//  Created by Mat Trudel on 2013-02-07.
//  Copyright (c) 2013 Mat Trudel. All rights reserved.
//

#import "MTCountingViewController.h"

#import "MTStackableNavigationController.h"
#import "UIViewController+MTStackableNavigationController.h"

@interface MTCountingViewController ()
@property(nonatomic) NSInteger number;
@property(nonatomic, weak) IBOutlet UILabel *numberLabel;
@end

@implementation MTCountingViewController

- (id)initWithNumber:(NSInteger)number {
  if (self = [super initWithNibName:nil bundle:nil]) {
    self.number = number;
  }
  return self;
}

- (void)viewDidLoad {
  self.numberLabel.text = [NSString stringWithFormat:@"%d", self.number];
}

- (IBAction)pushIncrementedController:(id)sender {
  MTCountingViewController *viewController = [[MTCountingViewController alloc] initWithNumber:self.number + 1];
  [self.stackableNavigationController pushViewController:viewController animated:YES];
}

- (IBAction)pushIncrementedControllerWithPeek:(id)sender {
  self.stackableNavigationItem.leftPeek = 20;
  [self pushIncrementedController:sender];
}

@end