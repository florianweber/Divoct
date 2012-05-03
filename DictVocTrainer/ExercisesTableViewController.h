/*
RecentsTableViewController.h
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
#import "DictionarySearchViewController.h"
#import "Collection.h"
#import "GenericHelpViewController.h"

@interface ExercisesTableViewController : GenericHelpTableViewController

@property (nonatomic, strong) Collection *collection; //exercises of this collection will be displayed in table view
@property (nonatomic) BOOL loadRecents; //if loadRecents is set (can be done as user defined attribute in interface builder) it loads recents on viewDidLoad

@end
