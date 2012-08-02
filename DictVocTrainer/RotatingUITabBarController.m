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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //only rotate in TrainingViewController and TrainingResultsViewController
    if((self.selectedIndex == 1) || (self.selectedIndex == 2)) {
        if([[[self.viewControllers objectAtIndex:self.selectedIndex] visibleViewController] isKindOfClass:[TrainingViewController class]]) {
            if (((TrainingViewController *)[[self.viewControllers objectAtIndex:self.selectedIndex] visibleViewController]).trainingMode == TrainingMode_TextInput) {
                return YES;
            }
        } else if ([[[self.viewControllers objectAtIndex:self.selectedIndex] visibleViewController] isKindOfClass:[TrainingResultsViewController class]]){
            if (((TrainingResultsViewController *)[[self.viewControllers objectAtIndex:self.selectedIndex] visibleViewController]).trainingMode == TrainingMode_TextInput) {
                return YES;
            }
        }
    }
    return NO;
}

@end
