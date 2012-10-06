//
//  CollectionPickerTableViewController.h
//  Divoct
//
//  Created by Florian Weber on 06.10.12.
//  Copyright (c) 2012 IBM. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GenericHelpViewController.h"

@class CollectionPickerViewController;

@protocol CollectionPickerViewControllerDelegate <NSObject>

-(void)collectionPickerViewController:(CollectionPickerViewController *)collectionPickerViewController pickedCollections:(NSMutableSet *)collections;

@end

@interface CollectionPickerViewController : GenericHelpViewController

@property (nonatomic, strong) id <CollectionPickerViewControllerDelegate> delegate;
@property (nonatomic, strong) NSMutableSet *selectedCollections;

@end


