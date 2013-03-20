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
  self.numberLabel.text = self.navigationItem.title = [NSString stringWithFormat:@"%d", self.number];
}

- (IBAction)pushIncrementedController:(id)sender {
  MTCountingViewController *viewController = [[MTCountingViewController alloc] initWithNumber:self.number + 1];

  if (self.navigationController) {
    [self.navigationController pushViewController:viewController animated:YES];
  } else {
    self.stackableNavigationItem.leftPeek = 0;
    [self.stackableNavigationController pushViewController:viewController animated:YES];
  }
}

- (IBAction)pushIncrementedControllerWithPeek:(id)sender {
  MTCountingViewController *viewController = [[MTCountingViewController alloc] initWithNumber:self.number + 1];

  if (self.navigationController) {
    [self.navigationController pushViewController:viewController animated:YES];
  } else {
    self.stackableNavigationItem.leftPeek = 20;
    [self.stackableNavigationController pushViewController:viewController animated:YES];
  }
}

- (IBAction)revealParentController:(id)sender {
  [self.stackableNavigationController revealParentControllerAnimated:YES];
}

- (IBAction)stopReveal:(id)sender {
  [self.stackableNavigationController endRevealAnimated:YES];
}

#pragma mark - Notification messages for various events - use these to verify adherence to UINavigationController semantics

- (void)viewWillAppear:(BOOL)animated {
  NSLog(@"View %d will appear", self.number);
}

- (void)viewDidAppear:(BOOL)animated {
  NSLog(@"View %d did appear", self.number);
}

- (void)viewWillDisappear:(BOOL)animated {
  NSLog(@"View %d will disappear", self.number);
}

- (void)viewDidDisappear:(BOOL)animated {
  NSLog(@"View %d did disappear", self.number);
}

- (void)viewWillLayoutSubviews {
  NSLog(@"View %d will layout subviews", self.number);
}

- (void)viewDidLayoutSubviews {
  NSLog(@"View %d did layout subviews", self.number);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  NSLog(@"View %d will rotate", self.number);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  NSLog(@"View %d will animate rotation", self.number);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  NSLog(@"View %d did rotate", self.number);
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
  NSLog(@"View %d will move to parent controller %@", self.number, parent);
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
  NSLog(@"View %d did move to parent controller %@", self.number, parent);
}

@end