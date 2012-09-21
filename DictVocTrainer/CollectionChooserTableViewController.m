/*
CollectionChooserTableViewController.m
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
#import "CollectionChooserTableViewController.h"
#import "DictVocTrainer.h"
#import "Logging.h"
#import "GlobalDefinitions.h"
#import "Collection.h"
#import "CollectionDetailViewController.h"
#import "FWToastView.h"

@interface CollectionChooserTableViewController () <CreateCollectionViewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *collections;
@property (nonatomic, strong) NSMutableDictionary *wordAssignments;
@property (nonatomic) BOOL needsReload;

@end

@implementation CollectionChooserTableViewController
@synthesize exercisesToAssign = _exercisesToAssign;
@synthesize word = _word;
@synthesize collections = _collections;
@synthesize wordAssignments = _wordAssignments;
@synthesize hideCollection = _hideCollection;
@synthesize needsReload = _needsReload;


#pragma mark - My Messages

- (void)addToCollection:(Collection *)collection
{
    if (self.word) {
        [self addWordToCollection:collection];
    } else if (self.exercisesToAssign) {
        [self addExercisesToCollection:collection];
    }
}

- (void)removeFromCollection:(Collection *)collection
{
    if (self.word) {
        [self removeWordFromCollection:collection];
    } else if (self.exercisesToAssign) {
        [self removeExercisesFromCollection:collection];
    }
}


- (void)addWordToCollection:(Collection *)collection
{
    Exercise *exercise = [[DictVocTrainer instance] exerciseWithWordUniqueId:self.word.uniqueId updateLastLookedUp:NO];
    [exercise addCollectionsObject:collection];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:DVT_COLLECTION_NOTIFICATION_CONTENTS_CHANGED object:nil]];
}

- (void)addExercisesToCollection:(Collection *)collection
{
    for (Exercise *exercise in self.exercisesToAssign) {
         [exercise addCollectionsObject:collection];
    }
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:DVT_COLLECTION_NOTIFICATION_CONTENTS_CHANGED object:nil]];
}

- (void)removeWordFromCollection:(Collection *)collection
{
    Exercise *exercise = [[DictVocTrainer instance] exerciseWithWordUniqueId:self.word.uniqueId updateLastLookedUp:NO];
    [[DictVocTrainer instance] deleteExercise:exercise fromCollection:collection];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:DVT_COLLECTION_NOTIFICATION_CONTENTS_CHANGED object:nil]];
}

- (void)removeExercisesFromCollection:(Collection *)collection
{
    for (Exercise *exercise in self.exercisesToAssign) {
        [[DictVocTrainer instance] deleteExercise:exercise fromCollection:collection];
    }
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:DVT_COLLECTION_NOTIFICATION_CONTENTS_CHANGED object:nil]];
}

- (void)loadWordAssignments
{
    int collectionCount = [self.collections count];
    self.wordAssignments = [[NSMutableDictionary dictionaryWithCapacity:collectionCount] mutableCopy];
    
    if(collectionCount > 0) {
        if (self.word) {
            for (Collection *collection in self.collections) {
                BOOL inThisCollection = [[DictVocTrainer instance] isWordWithUniqueId:self.word.uniqueId partOfCollection:(Collection *)collection];
                [self.wordAssignments setObject:[NSNumber numberWithBool:inThisCollection] forKey:collection.name];
            }
        } else if (self.exercisesToAssign) {
            for (Collection *collection in self.collections) {
                BOOL allInThisCollection = YES;
                for (Exercise *exercise in self.exercisesToAssign) {
                    if (![[DictVocTrainer instance] isWordWithUniqueId:exercise.wordUniqueId partOfCollection:(Collection *)collection]) {
                        allInThisCollection = NO;
                        break;
                    }
                }
                [self.wordAssignments setObject:[NSNumber numberWithBool:allInThisCollection] forKey:collection.name];
            }
        }
    }
}

-(void)addSwipeGestureRecognizer
{
    UISwipeGestureRecognizer *rightSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                                      action:@selector(handleSwipeFrom:)];
    rightSwiper.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwiper];
    
    UISwipeGestureRecognizer *leftSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                                     action:@selector(handleSwipeFrom:)];
    leftSwiper.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:leftSwiper];
}

-(void)loadContents
{
    self.collections = [[[DictVocTrainer instance] allCollections] mutableCopy];
    if (self.hideCollection) {
        [self.collections removeObject:self.hideCollection];
    }
    
    [self loadWordAssignments];
}

-(void)showHelp 
{
    [FWToastView toastInView:self.navigationController.view withText:NSLocalizedString(@"HELP_COLLECTION_CHOOSER", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
}

#pragma mark - Notifications

-(void)collectionInserted:(NSNotification *)notification
{
    self.needsReload = YES;
}

-(void)collectionDeleted:(NSNotification *)notification
{
    self.needsReload = YES;
}

#pragma mark - Target / Action

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        [[self navigationController] popViewControllerAnimated:YES];
    } else if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        [self performSegueWithIdentifier:@"Add Collection" sender:self];
    }
}

#pragma mark - CollectionDetails Controller Delegate

-(void)collectionDetailViewController:(CollectionDetailViewController *)sender finishedCreatingCollection:(Collection *)collection
{
    [self dismissModalViewControllerAnimated:YES];
    [self addToCollection:collection]; //real assignment
    [self.collections addObject:collection]; //for this view only
    [self.wordAssignments setObject:[NSNumber numberWithBool:YES] forKey:collection.name];
    
    [self.tableView beginUpdates];
    NSIndexPath *newIdxPath = [NSIndexPath indexPathForRow:[self.collections count]-1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIdxPath] withRowAnimation:UITableViewRowAnimationBottom];
    [self.tableView cellForRowAtIndexPath:newIdxPath].accessoryType = UITableViewCellAccessoryCheckmark;
    [self.tableView endUpdates];
    [self.tableView scrollToRowAtIndexPath:newIdxPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
}

-(void)collectionDetailViewController:(CollectionDetailViewController *)sender finishedEditingCollection:(Collection *)collection
{
    //not possible here
}

-(void)collectionDetailViewControllerGotCanceled:(CollectionDetailViewController *)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)collectionDetailViewController:(CollectionDetailViewController *)sender willDisappearWithImportantChanges:(BOOL)importantChanges
{
    //not important here
}

#pragma mark - Navigation Controller Delegate

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier hasPrefix:@"Add Collection"]) {
        CollectionDetailViewController *asker = (CollectionDetailViewController *)segue.destinationViewController;
        asker.delegate = self;
    }
    
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addSwipeGestureRecognizer];
    [self loadContents];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.needsReload) {
        [self loadContents];
        [self.tableView reloadData];
        self.needsReload = NO;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.exercisesToAssign) {
        if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
            // back button was pressed.  We know this is true because self is no longer
            // in the navigation stack.
            CATransition *transition = [CATransition animation];
            [transition setDuration:0.5];
            [transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
            [transition setType:@"oglFlip"];
            [transition setSubtype:kCATransitionFromRight];
            [transition setDelegate:self];
            [self.navigationController.view.layer addAnimation:transition forKey:nil];
        }
    }

    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(collectionInserted:) name:DVT_COLLECTION_NOTIFICATION_INSERTED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(collectionDeleted:) name:DVT_COLLECTION_NOTIFICATION_DELETED object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.collections count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Collection";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Collection *collection = [self.collections objectAtIndex:indexPath.row];
    
    if ([collection.name isEqualToString:NSLocalizedString(@"RECENTS_TITLE", nil)]) {
        cell.textLabel.text = NSLocalizedString(@"RECENTS_DISPLAY_TITLE", nil); 
        cell.detailTextLabel.text = NSLocalizedString(@"RECENTS_DESC", nil);
    } else {
        cell.textLabel.text = collection.name; 
        cell.detailTextLabel.text = collection.desc;
    }

    NSNumber *wordIsAssignedToThisCollectionAsNumber = [self.wordAssignments objectForKey:collection.name];
    
    if (!wordIsAssignedToThisCollectionAsNumber) {
        [self.wordAssignments setObject:[NSNumber numberWithBool:NO] forKey:collection.name];
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        if ([wordIsAssignedToThisCollectionAsNumber boolValue]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        } 
    }

    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        [self addToCollection:[self.collections objectAtIndex:indexPath.row]];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        [self removeFromCollection:[self.collections objectAtIndex:indexPath.row]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
