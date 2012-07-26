/*
RecentsTableViewController.m
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

#import <QuartzCore/QuartzCore.h>
#import "ExercisesTableViewController.h"
#import "SQLiteWord.h"
#import "DictVocTrainer.h"
#import "DictVocDictionary.h"
#import "VocabularyDetailViewController.h"
#import "Exercise+Extended.h"
#import "GlobalDefinitions.h"
#import "Logging.h"
#import "LoadingViewController.h"
#import "FWToastView.h"
#import "TrainingViewController.h"
#import "CollectionChooserTableViewController.h"

@interface ExercisesTableViewController () <LoadingViewControllerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) NSMutableOrderedSet *exercises;
@property (nonatomic, strong) NSDateFormatter *dateFormat;
@property (weak, nonatomic) IBOutlet UILabel *tableBottomLabel;
@property (nonatomic, strong) UIToolbar *editActionBar;
@property (nonatomic, strong) UIBarButtonItem *editButton;
@property (nonatomic, strong) UIBarButtonItem *deleteButton;
@property (nonatomic, strong) UIBarButtonItem *assignButton;
@property (nonatomic, strong) UIView *titleViewStore;
@property (nonatomic) BOOL needsReload;
@property (nonatomic) BOOL viewsHaveBeenSized;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIToolbar *rightNavigationItemToolbar;
@property (nonatomic) BOOL repairEditActionToolbar;
@property (nonatomic) NSArray *selectedRowsStore;
@property (nonatomic) CGRect editBarFrameStore;
@property (nonatomic) CGRect tableViewFrameStore;

-(void)updateCountDependentElementsLabel:(BOOL)updateNavigationItem;
-(void)updateTitleLabelWithText:(NSString *)text;

@end

@implementation ExercisesTableViewController
@synthesize collection = _collection;
@synthesize exercises = _exercises;
@synthesize dateFormat = _dateFormat;
@synthesize tableBottomLabel = _tableBottomLabel;
@synthesize editActionBar = _editActionBar;
@synthesize editButton = _editButton;
@synthesize deleteButton = _deleteButton;
@synthesize assignButton = _assignButton;
@synthesize loadRecents = _loadRecents;
@synthesize titleViewStore = _titleViewStore;
@synthesize needsReload = _needsReload;
@synthesize viewsHaveBeenSized = _viewsHaveBeenSized;
@synthesize titleLabel = _titleLabel;
@synthesize rightNavigationItemToolbar = _rightNavigationItemToolbar;
@synthesize repairEditActionToolbar = _repairEditActionToolbar;
@synthesize selectedRowsStore = _selectedRowsStore;

#pragma mark - Init


#pragma mark - Getter / Setter

-(UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:20];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = UITextAlignmentCenter;
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
        _titleLabel.userInteractionEnabled = YES;
    }
    return _titleLabel;
}

-(void)setExercises:(NSMutableOrderedSet *)exercises
{
    if (exercises != _exercises) {
        _exercises = exercises;
        [self updateCountDependentElementsLabel:YES];
    }
}

-(void)setCollection:(Collection *)collection
{
    if (collection) {
        _collection = collection;
        self.exercises = [self.collection.exercises mutableCopy];
        
        [self updateCountDependentElementsLabel:YES];
//        if (self.viewsHaveBeenSized) {
//            [self updateTitleLabelWithText:self.collection.name];
//        }
        
        //special case for recents
        if ([collection.name isEqualToString:NSLocalizedString(@"RECENTS_TITLE", nil)]) {
            [self.exercises sortUsingComparator:^NSComparisonResult(Exercise *exercise1, Exercise *exercise2){
                return [exercise2.lastLookedUp compare:exercise1.lastLookedUp];
            }];
            self.title = NSLocalizedString(@"RECENTS_DISPLAY_TITLE", nil);
            //[self.collection setExercises:self.exercises];
        } else {
           self.title = self.collection.name; 
        }
        
        [self.tableView reloadData];
    }
}

-(NSDateFormatter *)dateFormat
{
    if (!_dateFormat) {
        _dateFormat = [[NSDateFormatter alloc] init];
        
        [_dateFormat setTimeStyle:NSDateFormatterShortStyle];
        [_dateFormat setDateStyle:NSDateFormatterLongStyle];
        [_dateFormat setDoesRelativeDateFormatting:YES];
        
        NSLocale *currentLocale = [NSLocale currentLocale];
        LogDebug(@"Current locale: %@", currentLocale.localeIdentifier);
        [_dateFormat setLocale:currentLocale];
    }
    return  _dateFormat;
}

#pragma mark - My messages

-(void)updateTitleLabelWithText:(NSString *)text
{
    self.titleLabel.text = [text stringByAppendingFormat:@" (%i)", [self.exercises count]];
    
    int maxHeight = self.navigationController.navigationBar.frame.size.height;
    int maxWidth = self.navigationController.navigationBar.frame.size.width - self.navigationItem.leftBarButtonItem.width - self.navigationController.navigationBar.backItem.backBarButtonItem.width - self.navigationItem.rightBarButtonItem.width - 20;
    
    CGRect titleFrame = CGRectMake(0, 0, 0, 0);
    titleFrame.size = [self.titleLabel.text sizeWithFont:self.titleLabel.font constrainedToSize:CGSizeMake(maxWidth, maxHeight) lineBreakMode:UILineBreakModeTailTruncation];
    //titleFrame.origin = CGPointMake((self.navigationController.navigationBar.frame.size.width / 2) - (titleFrame.size.width / 2), (self.navigationController.navigationBar.frame.size.height / 2) - (titleFrame.size.height / 2));
    
    //this shows strange behaviour unfortunately
    int centerXbetweenLeftAndRightNavBarItems = self.navigationItem.leftBarButtonItem.width + (maxWidth / 2);
    titleFrame.origin = CGPointMake(centerXbetweenLeftAndRightNavBarItems - (titleFrame.size.width / 2), (maxHeight / 2) - (titleFrame.size.height / 2));
    self.titleLabel.frame = titleFrame;
    
    self.navigationItem.titleView = self.titleLabel;
    
    //add gesture recognizer to title
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(titleDoubleTap:)];
    tapGestureRecognizer.numberOfTapsRequired = 2;
    [self.navigationItem.titleView addGestureRecognizer:tapGestureRecognizer];
}

-(void)updateTitleLabelWithCollectionName
{
    if (self.loadRecents) {
        [self updateTitleLabelWithText:NSLocalizedString(@"RECENTS_DISPLAY_TITLE", nil)];
    } else {
        [self updateTitleLabelWithText:self.collection.name];
    }
}

-(void)observeDBChanges:(BOOL)observe
{
    if (observe) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                    selector:@selector(dbChanged:)
                                        name:NSManagedObjectContextObjectsDidChangeNotification
                                      object:[DictVocTrainer instance].dictVocTrainerDB.managedObjectContext];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

-(void)initRightNavigationItemBar
{
    if ([self.exercises count]) {
        int toolbarContentWidth = 0;
        
        //Toolbar for the Buttons
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 80.0f, 44.01f)]; // 44.01 shifts it up 1px for some reason
        toolbar.tintColor = [UIColor blackColor]; //self.navigationController.navigationBar.tintColor;
        toolbar.barStyle = -1; // clear background
        
        NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:4];
        //Spacer to move all items as far to the right as possible
        UIBarButtonItem *flexSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [buttons addObject:flexSpacer];

        //Edit Button
        UIImage *editImage = [UIImage imageNamed:@"pencilangled.png"];
        self.editButton = [[UIBarButtonItem alloc] initWithImage:editImage style:UIBarButtonItemStylePlain target:self action:@selector(editButtonPressed:)];
        if (self.tableView.editing) {
            self.editButton.tintColor = [UIColor blueColor];
        }
        [buttons addObject:self.editButton];
        toolbarContentWidth += 32;
        
        UIBarButtonItem *fixedSpacerItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixedSpacerItem.width = 5;
        [buttons addObject:fixedSpacerItem];
        toolbarContentWidth += fixedSpacerItem.width;
        
        //Training Button
        UIBarButtonItem *trainingButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gradhat.png"] style:UIBarButtonItemStylePlain target:self action:@selector(startTraining:)];
        [buttons addObject:trainingButton];
        toolbarContentWidth += 36;
        
        
        toolbar.frame = CGRectMake(0.0f, 0.0f, toolbarContentWidth + 10, 44.01f);
        self.rightNavigationItemToolbar = toolbar;
        
        //Add buttons to toolbar and turn it into a UIBarButtonItem with a custom view
        [toolbar setItems:buttons animated:NO];
        UIBarButtonItem *multipleButtons = [[UIBarButtonItem alloc] initWithCustomView:toolbar];
        self.navigationItem.rightBarButtonItem = multipleButtons;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

-(void)initEditActionBar
{
    if (!self.editActionBar) {
        NSMutableArray *itemsForToolbar = [[NSMutableArray alloc] init];
        if (self.editBarFrameStore.size.width > 0) {
            self.editActionBar = [[UIToolbar alloc] initWithFrame:self.editBarFrameStore];
        } else {
            self.editActionBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.tableView.frame.size.height, self.tableView.frame.size.width, 44)];
        }
        self.editActionBar.tintColor = [UIColor blackColor];
        
        //Delete
        self.deleteButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ (0)", NSLocalizedString(@"DELETE", nil)] style:UIBarButtonItemStyleBordered target:self action:@selector(deleteSelectedRows:)];
        self.deleteButton.tintColor = [UIColor redColor];
        self.deleteButton.enabled = NO;
        [itemsForToolbar addObject:self.deleteButton];
        
        //Assign
        self.assignButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ (0)", NSLocalizedString(@"ASSIGNSELECTED", nil)] style:UIBarButtonItemStyleBordered target:self action:@selector(assignSelectedRows:)];
        self.assignButton.tintColor = [UIColor blueColor];
        self.assignButton.enabled = NO;
        [itemsForToolbar addObject:self.assignButton];
        
        //Flex Spacer
        UIBarButtonItem *flexSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [itemsForToolbar addObject:flexSpacer];
        
        //Select all
        UIBarButtonItem *selectAllButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SELECTALL", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(selectAllRows:)];
        selectAllButton.tintColor = [UIColor grayColor];
        [itemsForToolbar addObject:selectAllButton];
        
        //Deselect all
        UIBarButtonItem *deselectAllButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"DESELECTALL", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(deselectAllRows:)];
        deselectAllButton.tintColor = [UIColor grayColor];
        
        [itemsForToolbar addObject:deselectAllButton];
        
        [self.editActionBar setItems:itemsForToolbar];
    }
}

-(void)updateCountDependentElementsLabel:(BOOL)updateNavigationItem
{
    if (self.collection) {
        int entryCount = [self.exercises count];
        [self updateTitleLabelWithCollectionName];
        
        if (entryCount) {
            if (((entryCount == 1) && updateNavigationItem) || ((entryCount >= 1) && !self.navigationItem.rightBarButtonItem)) {
                [self initRightNavigationItemBar];
            }
            
            if (entryCount == 1) {
                self.tableBottomLabel.text = [NSString stringWithFormat:@"%@ %i %@.", NSLocalizedString(@"WORDS_IN_LIST_P1_SL", nil), [self.exercises count], NSLocalizedString(@"WORDS_IN_LIST_P2_SL", nil)];
            } else {
                self.tableBottomLabel.text = [NSString stringWithFormat:@"%@ %i %@.", NSLocalizedString(@"WORDS_IN_LIST_P1_PL", nil), [self.exercises count], NSLocalizedString(@"WORDS_IN_LIST_P2_PL", nil)];
            }
            
        } else {
            if (self.loadRecents) {
                self.tableBottomLabel.text = [NSString stringWithFormat:@"%@.\n%@.", NSLocalizedString(@"WORDS_IN_LIST_NO", nil), NSLocalizedString(@"WORDS_IN_LIST_RECENT_AUTO", nil)];
            } else {
                self.tableBottomLabel.text = [NSString stringWithFormat:@"%@.\n%@.", NSLocalizedString(@"WORDS_IN_LIST_NO", nil), NSLocalizedString(@"WORDS_IN_LIST_P3", nil)];
            }
            [self initRightNavigationItemBar];
            if (self.tableView.editing && updateNavigationItem) {
                self.tableView.editing = NO;
                [self showActionBar:NO];
            }
        }
    }
}

-(void)updateSelectedDependentButtons
{
    [self updateAssignButton];
    [self updateDeleteButton];
}

-(void)updateDeleteButton
{
    int selectedEntriesCount =  [self.tableView.indexPathsForSelectedRows count];
    self.deleteButton.title = [NSString stringWithFormat:@"%@ (%i)", NSLocalizedString(@"DELETE", nil), selectedEntriesCount];
    
    if (selectedEntriesCount) {
        self.deleteButton.enabled = YES;
    } else {
        self.deleteButton.enabled = NO;
    }
}

-(void)updateAssignButton
{
    int selectedEntriesCount =  [self.tableView.indexPathsForSelectedRows count];
    self.assignButton.title = [NSString stringWithFormat:@"%@ (%i)", NSLocalizedString(@"ASSIGNSELECTED", nil), selectedEntriesCount];
    
    if (selectedEntriesCount) {
        self.assignButton.enabled = YES;
    } else {
        self.assignButton.enabled = NO;
    }
}

-(void)showActionBar:(BOOL)show
{
    CGRect toolbarFrame = self.editActionBar.frame;
    CGRect tableViewFrame = self.tableView.frame;
    
    if (show) {
        [self.tableView.superview addSubview:self.editActionBar];
        toolbarFrame.origin.y = self.tableView.frame.size.height - toolbarFrame.size.height;
        tableViewFrame.size.height -= toolbarFrame.size.height;
    } else {
        tableViewFrame.size.height += toolbarFrame.size.height;
        toolbarFrame.origin.y = self.tableView.frame.size.height;
    }
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    self.editActionBar.frame = toolbarFrame;
    self.tableView.frame = tableViewFrame;
    
    [UIView commitAnimations];
    
    if (!show) {
        [self.editActionBar removeFromSuperview];
    }
    self.editBarFrameStore = self.editActionBar.frame;
    self.tableViewFrameStore = self.tableView.frame;
}

-(void)furtherViewDidLoadSetup
{
    if (self.loadRecents) {
        self.collection = [[DictVocTrainer instance] collectionWithName:NSLocalizedString(@"RECENTS_TITLE", nil)];
    }
    
    [self initRightNavigationItemBar];
    [self initEditActionBar];
}

-(void)showHelp 
{
    if (self.loadRecents && ([self.exercises count] > 0)) {
        [FWToastView toastInView:self.navigationController.view withText:NSLocalizedString(@"HELP_RECENTS", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
    } else if (self.loadRecents && ([self.exercises count] <= 0)) {
        [FWToastView toastInView:self.navigationController.view withText:NSLocalizedString(@"HELP_RECENTS_EMPTY", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
    } else if ([self.exercises count] > 0) {
        [FWToastView toastInView:self.navigationController.view withText:NSLocalizedString(@"HELP_EXERCISES", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
    } else {
        [FWToastView toastInView:self.navigationController.view withText:NSLocalizedString(@"HELP_EXERCISES_EMPTY", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
    }
}

#pragma mark - Notifications

-(void)dbChanged:(NSNotification *)notification
{
    for (id object in [notification.userInfo objectForKey:NSUpdatedObjectsKey]) {
        if ([object isKindOfClass:[Collection class]]) {
            if ([((Collection *)object) isEqual:self.collection]) {
                self.needsReload = YES;
            }
        } else if ([object isKindOfClass:[Exercise class]]) {
            if ([self.collection.exercises containsObject:((Exercise *)object)]) {
                self.needsReload = YES;
            }
        }
    }
    
    for (id object in [notification.userInfo objectForKey:NSDeletedObjectsKey]) {
        if ([object isKindOfClass:[Collection class]]) {
            if ([((Collection *)object) isEqual:self.collection]) {
                self.needsReload = YES;
            }
        }
    }
}


#pragma mark - Target / Action

-(IBAction)startTraining:(id)sender
{
    if (self.tableView.editing) {
        [self editButtonPressed:[self.rightNavigationItemToolbar.items objectAtIndex:1]];
    }
    [self performSegueWithIdentifier:@"Show Training" sender:self];
}

- (IBAction)editButtonPressed:(UIBarButtonItem *)sender {
    
    if (self.tableView.editing) {
        self.tableView.allowsMultipleSelectionDuringEditing = NO;
        [self.tableView setEditing:NO animated:YES];
        [self showActionBar:NO];
        sender.tintColor = [UIColor blackColor];
        [self updateCountDependentElementsLabel:YES];
    } else {
        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        [self.tableView setEditing:YES animated:YES];
        sender.tintColor = [UIColor blueColor];
        [self showActionBar:YES];
        [self updateCountDependentElementsLabel:YES];
        [self updateSelectedDependentButtons];
    }
}

-(IBAction)deleteSelectedRows:(id)sender
{
    NSMutableArray *recentsToDelete = [[NSMutableArray alloc] initWithCapacity:[self.tableView.indexPathsForSelectedRows count]];
    for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
        Exercise *exercise = [self.exercises objectAtIndex:indexPath.row];
        [recentsToDelete addObject:exercise];
    }
    
    for (Exercise *exercise in recentsToDelete) {
        [[DictVocTrainer instance] deleteExercise:exercise fromCollection:self.collection];
    }
    
    [self.exercises removeObjectsInArray:recentsToDelete];
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:self.tableView.indexPathsForSelectedRows withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    
    [self updateCountDependentElementsLabel:YES];
    [self updateSelectedDependentButtons];
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:DVT_COLLECTION_NOTIFICATION_CONTENTS_CHANGED object:self.collection]];
}

-(IBAction)assignSelectedRows:(id)sender
{
    [self performSegueWithIdentifier:@"Organize in Collections" sender:nil];
}

-(IBAction)selectAllRows:(id)sender
{
    NSMutableArray *allIndexPaths = [[NSMutableArray alloc] initWithCapacity:[self.exercises count]];
    for (int i=0; i<[self.exercises count]; i++) {
        [allIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    for (NSIndexPath *indexPath in allIndexPaths) {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    
    [self updateSelectedDependentButtons];
}

-(IBAction)deselectAllRows:(id)sender
{
    NSMutableArray *allIndexPaths = [[NSMutableArray alloc] initWithCapacity:[self.exercises count]];
    for (int i=0; i<[self.exercises count]; i++) {
        [allIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    for (NSIndexPath *indexPath in allIndexPaths) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    [self updateSelectedDependentButtons];
}

-(void)titleDoubleTap:(UITapGestureRecognizer *)recognizer
{
    if (![self.collection.name isEqualToString:NSLocalizedString(@"RECENTS_TITLE", nil)]) {
        self.titleViewStore = self.navigationItem.titleView;
        
        int maxHeight = self.navigationController.navigationBar.frame.size.height;
        int maxWidth = 0;
        for (UIView *navigationBarSubview in self.navigationController.navigationBar.subviews) {
            maxWidth += navigationBarSubview.frame.size.width;
        }
        
        CGRect titleChangeFieldFrame = self.navigationItem.titleView.frame;
        titleChangeFieldFrame.size = CGSizeMake(maxWidth, maxHeight - 20);
        
        UITextField *titleChangeField = [[UITextField alloc] initWithFrame:titleChangeFieldFrame];
        titleChangeField.borderStyle = UITextBorderStyleRoundedRect;
        titleChangeField.backgroundColor = [UIColor whiteColor];
        titleChangeField.delegate = self;
        titleChangeField.text = self.collection.name;
        titleChangeField.returnKeyType = UIReturnKeyDone;
        
        self.navigationItem.titleView = titleChangeField;
        [((UITextField *)self.navigationItem.titleView) becomeFirstResponder];
    }
}

#pragma mark - UITextfield Delegate

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    [self updateTitleLabelWithCollectionName];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL returnValue = NO;
    
    NSString *cleanTitle = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSUInteger newLength = [cleanTitle length];
    
    if ([cleanTitle length]) {
        
        if (newLength > DVT_MAX_COLLECTION_NAME_LENGTH) {
            [FWToastView toastInView:self.view withText:[NSString stringWithFormat:@"%@ %i %@.", NSLocalizedString(@"TITLE_TOO_LONG_P1", nil), DVT_MAX_COLLECTION_NAME_LENGTH, NSLocalizedString(@"TITLE_TOO_LONG_P2", nil)] icon:FWToastViewIconWarning duration:FWToastViewDurationDefault withCloseButton:YES];
            returnValue = NO;
        } else if ([self.collection.name isEqualToString:cleanTitle]) {
            [textField resignFirstResponder];
            returnValue = YES;
        } else {
            Collection *newCollection = [[DictVocTrainer instance] readCollectionWithName:cleanTitle];
            if (!newCollection) {
                self.collection.name = cleanTitle;
                [textField resignFirstResponder];
                returnValue = YES;
            } else {
                [FWToastView toastInView:self.view withText:NSLocalizedString(@"TITLE_NAME_GIVEN", nil) icon:FWToastViewIconWarning duration:FWToastViewDurationDefault withCloseButton:YES];
                returnValue = NO;
            }
        }
    } else {
        [FWToastView toastInView:self.view withText:NSLocalizedString(@"TITLE_NOT_EMPTY", nil) icon:FWToastViewIconWarning duration:FWToastViewDurationDefault withCloseButton:YES];
        returnValue = NO;
    }
    
    if(returnValue) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:DVT_COLLECTION_NOTIFICATION_RENAMED object:self.collection]];
    }
    
    return returnValue;
}


#pragma mark - Navigation Controller Delegate

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Vocabulary Details"]) {
        [segue.destinationViewController setExercise:[self.exercises objectAtIndex:((NSIndexPath *)sender).row]];
        [segue.destinationViewController setEditTrainingTranslationsButtonEnabled:YES];
        
    } else if ([segue.identifier isEqualToString:@"Show Training"]) {
        [segue.destinationViewController setCollection:self.collection];
        
    } else if ([segue.identifier isEqualToString:@"Organize in Collections"]) {
        
        NSMutableArray *selectedExercises = [[NSMutableArray alloc] initWithCapacity:[self.tableView.indexPathsForSelectedRows count]];
        for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
            Exercise *exercise = [self.exercises objectAtIndex:indexPath.row];
            [selectedExercises addObject:exercise];
        }
        self.selectedRowsStore = self.tableView.indexPathsForSelectedRows;
        
        [segue.destinationViewController setHideCollection:self.collection];
        [segue.destinationViewController setExercisesToAssign:selectedExercises];
        self.repairEditActionToolbar = YES;
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[DictVocDictionary instance] firstTimeSetupRequired]) {
        //show activity view
        LoadingViewController *loadingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Loading View"];
        loadingViewController.delegate = self;
        loadingViewController.text = NSLocalizedString(@"SETUP", nil);
        [loadingViewController startAnimating];
        loadingViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self.tabBarController presentViewController:loadingViewController animated:YES completion:^{
            LogDebug(@"Loading View should be presented");
        }];
        
        //setup database (unzip and init)
        [[DictVocDictionary instance] setupDatabaseWithCompletionBlock:^(NSError *error){
            if (error) {
                [loadingViewController setText:[error localizedDescription]];
            } else {
                //init training database
                [[DictVocTrainer instance] openDictVocTrainerDBUsingBlock:^(NSError *error) {
                    if (error) {
                        loadingViewController.text = [error localizedDescription];
                    } else {
                        [self furtherViewDidLoadSetup];
                        [loadingViewController stopAnimating];
                        [self.tabBarController dismissViewControllerAnimated:YES completion:^{
                            LogDebug(@"Loading View should be dismissed");
                        }];
                    }
                }];

            }
        }];
    } else {
        //init spinner
        __block UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.hidesWhenStopped = YES;
        [spinner startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
        
        //init dictionary database
        NSError *error = [[DictVocDictionary instance] openDatabaseWithFileName:DVT_DB_FILE_NAME];
        if (error) {
            spinner = nil;
            LoadingViewController *loadingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Loading View"];
            loadingViewController.text = [error localizedDescription];
            [self.tabBarController presentViewController:loadingViewController animated:YES completion:nil];
        }
        
        //init training database
        [[DictVocTrainer instance] openDictVocTrainerDBUsingBlock:^(NSError *error) {
            if (error) {
                LoadingViewController *loadingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Loading View"];
                loadingViewController.text = [error localizedDescription];
                [self.tabBarController presentViewController:loadingViewController animated:YES completion:nil];
            } else {
                [self furtherViewDidLoadSetup];
            }
            [spinner stopAnimating];
            spinner = nil;
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.viewsHaveBeenSized = YES;
    [self observeDBChanges:NO];
    
    if (self.collection) {
        [self updateCountDependentElementsLabel:YES];
    }
    
    if (![self.titleLabel.text length]) {
        [self updateTitleLabelWithCollectionName];
    }
    
    if (self.needsReload) {
        //reload
        if (self.loadRecents) {
            self.collection = [[DictVocTrainer instance] collectionWithName:NSLocalizedString(@"RECENTS_TITLE", nil)];
        } else {
            self.collection = self.collection;
        }

        self.needsReload = NO;
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    if (self.editBarFrameStore.size.width > 0) {
        self.editActionBar.frame = self.editBarFrameStore;
        self.tableView.frame = self.tableViewFrameStore;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //there seems to be a bug with the animations and my toolbar, so this is a workaround
    if (self.repairEditActionToolbar) {
        self.repairEditActionToolbar = NO;
        [self.tableView.superview addSubview:self.editActionBar];
        self.editActionBar.frame = self.editBarFrameStore;
        self.tableView.frame = self.tableViewFrameStore;
        
        for (NSIndexPath *indexPath in self.selectedRowsStore) {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:NO];
        }
        self.selectedRowsStore = nil;
        [self updateSelectedDependentButtons];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:NO];
    self.viewsHaveBeenSized = NO;
    [self observeDBChanges:YES];
}

- (void)viewDidUnload
{
    [self observeDBChanges:NO];
    [self setTableBottomLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.exercises count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Exercise *recent = [self.exercises objectAtIndex:indexPath.row];
    static NSString *CellIdentifier = @"Exercise - Right Image";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.textLabel.text = recent.word.name;
        cell.detailTextLabel.text = [recent.word.language stringByAppendingString:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"SEARCHED", nil), [self.dateFormat stringFromDate:recent.lastLookedUp]]];
    } else {
        ((UILabel *)([cell viewWithTag:10])).text = recent.word.name;
        ((UILabel *)([cell viewWithTag:12])).text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"SEARCHED", nil), [self.dateFormat stringFromDate:recent.lastLookedUp]];
        switch ([recent.word.languageCode intValue]) {
            case WordLanguageGerman:
                ((UIImageView *)([cell viewWithTag:11])).image = [UIImage imageNamed:@"flagGermany.png"];
                break;
                
            case WordLanguageEnglish:
                ((UIImageView *)([cell viewWithTag:11])).image = [UIImage imageNamed:@"flagUK.png"];
                
            default:
                break;
        }
        
    }
    
    return cell;
}

- (void)    tableView:(UITableView *)tableView 
   commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
    forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        Exercise *exercise = [self.exercises objectAtIndex:indexPath.row];
        [[DictVocTrainer instance] deleteExercise:exercise fromCollection:self.collection];
        
        [self.exercises removeObject:exercise];
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        
        [self updateCountDependentElementsLabel:NO];
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:DVT_COLLECTION_NOTIFICATION_CONTENTS_CHANGED object:self.collection]];
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing) {
        [self updateSelectedDependentButtons];
    } else {
        [self performSegueWithIdentifier:@"Show Vocabulary Details" sender:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing) {
        [self updateSelectedDependentButtons];
    }
}

@end
