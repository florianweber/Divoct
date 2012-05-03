/*
CreateCollectionViewController.h
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


#import <UIKit/UIKit.h>
#import "Collection.h"
#import "GenericHelpViewController.h"

@class CollectionDetailViewController;

@protocol CreateCollectionViewControllerDelegate <NSObject>

-(void)collectionDetailViewController:(CollectionDetailViewController *)sender finishedCreatingCollection:(Collection *)collection;
-(void)collectionDetailViewController:(CollectionDetailViewController *)sender finishedEditingCollection:(Collection *)collection;
-(void)collectionDetailViewControllerGotCanceled:(CollectionDetailViewController *)sender;
-(void)collectionDetailViewController:(CollectionDetailViewController *)sender willDisappearWithImportantChanges:(BOOL)importantChanges; 

@end

@interface CollectionDetailViewController : GenericHelpViewController

@property (nonatomic) BOOL importantChanges;
@property (nonatomic, strong) Collection *collection;
@property (nonatomic, strong) id <CreateCollectionViewControllerDelegate> delegate;

@end
