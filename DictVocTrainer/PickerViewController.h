//
//  PickerViewController.h
//  Divoct
//
//  Created by Florian Weber on 09.08.12.
//  Copyright (c) 2012 IBM. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PickerViewController;

@protocol PickerViewControllerDelegate <NSObject>

-(void)pickerViewController:(PickerViewController *)pickerViewController pickedValue:(NSString *)value;

@end


@interface PickerViewController : UIViewController

@property (nonatomic, strong) NSArray *pickList;
@property (nonatomic) NSInteger preselectedRow;
@property (nonatomic, strong) id <PickerViewControllerDelegate> delegate;

@end
