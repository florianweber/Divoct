/*
GenericHelpViewController.m
 DictVocTrainer
 
 Copyright (C) 2012  Florian Weber
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */


#import "GenericHelpViewController.h"
#import "FWToastView.h"

// -- Generic Help View Controller --------------------------------------------------------------------------------------------------------------------------------------------------------------

@interface GenericHelpViewController ()

@end

@implementation GenericHelpViewController

//- (void)showHelp
//{
//    //overwrite this method to display help messages on the screen
//}


- (void)viewDidLoad
{
    [super viewDidLoad];
	
    //Two Finger Tap for help
    UITapGestureRecognizer *twoFingerTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showHelp)];
    twoFingerTapGestureRecognizer.numberOfTapsRequired = 1;
    twoFingerTapGestureRecognizer.numberOfTouchesRequired = 2;
    [self.view addGestureRecognizer:twoFingerTapGestureRecognizer];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ([FWToastView isAToastActive]) {
        [FWToastView dismissAllToasts];
        [self performSelector:@selector(showHelp)];
    }
}

@end



// -- Generic Help Table View Controller --------------------------------------------------------------------------------------------------------------------------------------------------------

@interface GenericHelpTableViewController ()

@end

@implementation GenericHelpTableViewController

//- (void)showHelp
//{
//    //overwrite this method to display help messages on the screen
//}


- (void)viewDidLoad
{
    [super viewDidLoad];
	
    //Two Finger Tap for help
    UITapGestureRecognizer *twoFingerTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showHelp)];
    twoFingerTapGestureRecognizer.numberOfTapsRequired = 1;
    twoFingerTapGestureRecognizer.numberOfTouchesRequired = 2;
    [self.view addGestureRecognizer:twoFingerTapGestureRecognizer];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ([FWToastView isAToastActive]) {
        [FWToastView dismissAllToasts];
        [self performSelector:@selector(showHelp)];
    }
}

@end
