//
//  RotatingUITabBarController.m
//  Divoct
//
//  Created by Florian Weber on 02.08.12.
//  Copyright (c) 2012 IBM. All rights reserved.
//

#import "RotatingUITabBarController.h"
#import "TrainingViewController.h"
#import "TrainingResultsViewController.h"
#import "GlobalDefinitions.h"
#import "Training.h"

@interface RotatingUITabBarController ()

@end

@implementation RotatingUITabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    /* Todo: iOS 6 will not rotate back automatically from training as it did in iOS 5, so I will have to make all views compatible with landscape mode first
    //only rotate in TrainingViewController and TrainingResultsViewController
    if((self.selectedIndex == 1) || (self.selectedIndex == 2)) {
        if([[[self.viewControllers objectAtIndex:self.selectedIndex] visibleViewController] isKindOfClass:[TrainingViewController class]]) {
            if (((TrainingViewController *)[[self.viewControllers objectAtIndex:self.selectedIndex] visibleViewController]).training.trainingAnswerInputMode == TrainingAnswerInputMode_TextInput) {
                return UIInterfaceOrientationMaskAll;
            }
        } else if ([[[self.viewControllers objectAtIndex:self.selectedIndex] visibleViewController] isKindOfClass:[TrainingResultsViewController class]]){
            if (((TrainingResultsViewController *)[[self.viewControllers objectAtIndex:self.selectedIndex] visibleViewController]).training.trainingAnswerInputMode == TrainingAnswerInputMode_TextInput) {
                return UIInterfaceOrientationMaskAll;
            }
        }
    }
     */
    //return UIInterfaceOrientationMaskPortrait;
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //only rotate in TrainingViewController and TrainingResultsViewController
    if((self.selectedIndex == 1) || (self.selectedIndex == 2)) {
        if([[[self.viewControllers objectAtIndex:self.selectedIndex] visibleViewController] isKindOfClass:[TrainingViewController class]]) {
            if (((TrainingViewController *)[[self.viewControllers objectAtIndex:self.selectedIndex] visibleViewController]).training.trainingAnswerInputMode == TrainingAnswerInputMode_TextInput) {
                return YES;
            }
        } else if ([[[self.viewControllers objectAtIndex:self.selectedIndex] visibleViewController] isKindOfClass:[TrainingResultsViewController class]]){
            if (((TrainingResultsViewController *)[[self.viewControllers objectAtIndex:self.selectedIndex] visibleViewController]).training.trainingAnswerInputMode == TrainingAnswerInputMode_TextInput) {
                return YES;
            }
        }
    }
   return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
