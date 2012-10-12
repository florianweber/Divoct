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
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
   return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
