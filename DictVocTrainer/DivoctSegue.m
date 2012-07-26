//
//  DivcotSegue.m
//  Divoct
//
//  Created by Florian Weber on 26.07.12.
//  Copyright (c) 2012 IBM. All rights reserved.
//

#import "DivoctSegue.h"

@implementation DivoctSegue

- (void) perform {
    
    UIViewController *src = (UIViewController *) self.sourceViewController;
    UIViewController *dst = (UIViewController *) self.destinationViewController;
    
    [UIView transitionWithView:src.navigationController.view duration:0.5
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                                    [src.navigationController pushViewController:dst animated:NO];
                                }
                    completion: NULL];
    
}

@end
