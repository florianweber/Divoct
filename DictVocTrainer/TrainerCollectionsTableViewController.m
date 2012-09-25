/*
TrainerCollectionsTableViewController.m
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


#import "TrainerCollectionsTableViewController.h"
#import "DictVocTrainer.h"
#import "Logging.h"
#import "GlobalDefinitions.h"
#import "LoadingViewController.h"
#import "DictVocDictionary.h"
#import "Collection.h"
#import "ExercisesTableViewController.h"
#import "CollectionDetailViewController.h"
#import "FWToastView.h"

@interface TrainerCollectionsTableViewController () <UITabBarControllerDelegate, LoadingViewControllerDelegate, CreateCollectionViewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *collections;
@property (nonatomic, strong) UIToolbar *editActionBar;
@property (nonatomic, strong) UIBarButtonItem *deleteButton;
@property (nonatomic, strong) UIBarButtonItem *leftNavigationItemEditItem;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) BOOL needsReload;
@end

@implementation TrainerCollectionsTableViewController
@synthesize collections = _collections;
@synthesize editActionBar = _editActionBar;
@synthesize deleteButton = _deleteButton;
@synthesize leftNavigationItemEditItem = _leftNavigationItemEditItem;
@synthesize needsReload = _needsReload;
@synthesize activityIndicator = _activityIndicator;
CGRect editBarFrameStore; 

#pragma mark - Getter / Setter

-(void)setCollections:(NSMutableArray *)collections
{
    _collections = collections;
    [self initRightNavigationItemBar];
}

-(UIBarButtonItem *)leftNavigationItemEditItem
{
    if (!_leftNavigationItemEditItem) {
        //Toolbar for the Buttons
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 103.0f, 44.01f)]; // 44.01 shifts it up 1px for some reason
        toolbar.tintColor = [UIColor blackColor]; //self.navigationController.navigationBar.tintColor;
        toolbar.barStyle = -1; // clear background
        
        NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:4];
        
        //Edit Button
        UIBarButtonItem *createButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newButtonPressed:)];
        [buttons addObject:createButton];
        
        //Add buttons to toolbar and turn it into a UIBarButtonItem with a custom view
        [toolbar setItems:buttons animated:NO];
        _leftNavigationItemEditItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];
    }
    return _leftNavigationItemEditItem;
}


#pragma mark - My Messages

-(UIActivityIndicatorView *)createAndDisplayActivityIndicator {
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.activityIndicator setHidesWhenStopped:YES];
    [self.activityIndicator stopAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_activityIndicator];
    return _activityIndicator;
}

-(void)initRightNavigationItemBar
{
    if ([self.collections count] > 0) {
        //Toolbar for the Buttons
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 103.0f, 44.01f)]; // 44.01 shifts it up 1px for some reason
        toolbar.tintColor = [UIColor blackColor]; //self.navigationController.navigationBar.tintColor;
        toolbar.barStyle = -1; // clear background
        
        NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:4];
        //Spacer to move all items as far to the right as possible
        UIBarButtonItem *flexSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [buttons addObject:flexSpacer];
        
        //Edit Button
        UIImage *editImage = [UIImage imageNamed:@"pencilangled.png"];
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithImage:editImage style:UIBarButtonItemStylePlain target:self action:@selector(editButtonPressed:)];
        [buttons addObject:editButton];
        
        //Add buttons to toolbar and turn it into a UIBarButtonItem with a custom view
        [toolbar setItems:buttons animated:NO];
        UIBarButtonItem *multipleButtons = [[UIBarButtonItem alloc] initWithCustomView:toolbar];
        self.navigationItem.rightBarButtonItem = multipleButtons;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

-(void)showHelp 
{
    if ([self.collections count] <= 0) {
        [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_COLLECTIONS_EMPTY", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES pointingToView:[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] fromDirection:FWToastViewPointingFromDirectionBottom];
    } else if (self.tableView.editing) {
        [FWToastView toastInView:self.navigationController.view withText:NSLocalizedString(@"HELP_COLLECTIONS_EDIT", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
    } else {    
        [FWToastView toastInView:self.navigationController.view withText:NSLocalizedString(@"HELP_COLLECTIONS_FILLED", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
    }
}


-(void)showLeftNavigationItemCustomToolbar:(BOOL)show
{
    NSMutableArray *leftButtonsArray = [self.navigationItem.leftBarButtonItems mutableCopy];
    if (!leftButtonsArray) {
        leftButtonsArray = [[NSMutableArray alloc] initWithCapacity:1];
    }
    
    if (show) {
        [leftButtonsArray addObject:self.leftNavigationItemEditItem];
    } else {
       [leftButtonsArray removeObject:self.leftNavigationItemEditItem]; 
    }
    
    self.navigationItem.leftBarButtonItems = leftButtonsArray;
}


#pragma mark - Notifications

-(void)collectionInserted:(NSNotification *)notification
{
    self.collections = [[[DictVocTrainer instance] allCollectionsExceptRecents] mutableCopy];
    self.needsReload = YES;
}

-(void)collectionRenamed:(NSNotification *)notification
{
    self.needsReload = YES;
}

-(void)collectionContentsChanged:(NSNotification *)notification
{
    self.needsReload = YES;
}


#pragma mark - Target / Action

- (IBAction)editButtonPressed:(UIBarButtonItem *)sender {
    
    if (self.tableView.editing) {
        [self.tableView setEditing:NO animated:YES];
        //[self showLeftNavigationItemCustomToolbar:NO];
        sender.tintColor = [UIColor blackColor];
    } else {
        [self.tableView setEditing:YES animated:YES];
        sender.tintColor = [UIColor blueColor];
        //[self showLeftNavigationItemCustomToolbar:YES];
    }
}

- (IBAction)newButtonPressed:(UIBarButtonItem *)sender 
{
    [self performSegueWithIdentifier:@"Show Collection Detail" sender:sender];
}



#pragma mark - CollectionDetails Controller Delegate

-(void)collectionDetailViewController:(CollectionDetailViewController *)sender finishedCreatingCollection:(Collection *)collection
{
    [self dismissModalViewControllerAnimated:YES];
    [self.collections addObject:collection];
    
    if ([self.collections count] == 1) {
        [self initRightNavigationItemBar];
    }
    
    if (self.tableView.editing) {
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self.collections count]-1 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
        [self.tableView endUpdates];
    } else {
        [self.tableView reloadData];
    }
}

-(void)collectionDetailViewController:(CollectionDetailViewController *)sender finishedEditingCollection:(Collection *)collection
{
    [self dismissModalViewControllerAnimated:YES];
    [self.tableView reloadData];
}

-(void)collectionDetailViewControllerGotCanceled:(CollectionDetailViewController *)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)collectionDetailViewController:(CollectionDetailViewController *)sender willDisappearWithImportantChanges:(BOOL)importantChanges
{
    if (!importantChanges) {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
}


#pragma mark - Navigation Controller Delegate

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Collection"]) {
        [segue.destinationViewController setCollection:[self.collections objectAtIndex:((NSIndexPath *)sender).row]];
    } else if ([segue.identifier hasPrefix:@"Show Collection Detail"]) {
        CollectionDetailViewController *asker = (CollectionDetailViewController *)segue.destinationViewController;
        asker.delegate = self;
        
        if ([sender isKindOfClass:[NSIndexPath class]]) {
            asker.collection = [self.collections objectAtIndex:((NSIndexPath *)sender).row];
        }
    }

}

#pragma mark - UITabBarController delegate

-(BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if ([self.activityIndicator isAnimating]) {
        return NO;
    }
    return YES;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tabBarController setDelegate:self];
    
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
                [loadingViewController stopAnimating];
                [self.tabBarController dismissViewControllerAnimated:YES completion:^{
                    LogDebug(@"Loading View should be dismissed");
                }];
                self.collections = [[[DictVocTrainer instance] allCollectionsExceptRecents] mutableCopy];
                [self showLeftNavigationItemCustomToolbar:YES];

            }
        }];
    } else {
        //init spinner
        [self createAndDisplayActivityIndicator];
        [self.activityIndicator startAnimating];
        
        //init dictionary database
        NSError *error = [[DictVocDictionary instance] openDatabaseWithFileName:DVT_DB_FILE_NAME];
        if (error) {
            [self.activityIndicator stopAnimating];
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
                [self.activityIndicator stopAnimating];
                self.collections = [[[DictVocTrainer instance] allCollectionsExceptRecents] mutableCopy];
                [self showLeftNavigationItemCustomToolbar:YES];
            }
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (![self.collections count]) {
        self.collections = [[[DictVocTrainer instance] allCollectionsExceptRecents] mutableCopy];
        [self.tableView reloadData];
    }
    
    if (self.needsReload) {
        [self.tableView reloadData];
        self.needsReload = NO;
    }
        
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(collectionRenamed:) name:DVT_COLLECTION_NOTIFICATION_RENAMED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(collectionInserted:) name:DVT_COLLECTION_NOTIFICATION_INSERTED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(collectionContentsChanged:) name:DVT_COLLECTION_NOTIFICATION_CONTENTS_CHANGED object:nil];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    if (editBarFrameStore.size.width > 0) {
        self.editActionBar.frame = editBarFrameStore;
    }
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return [self.collections count] ? [self.collections count] : 1;
            break;
            
        default:
            return 0;
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        int collectionCount = [self.collections count];
        if (collectionCount) {
            return NSLocalizedString(@"VOCABULARY_COLLECTION_TITLE", nil);
        } else {
            return NSLocalizedString(@"VOCABULARY_COLLECTION_TITLE_NONEYET", nil);
        }
    } else {
        return NSLocalizedString(@"UNKNOWN", nil);
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == 0) {
        if (![self.collections count]) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.textLabel.text = NSLocalizedString(@"VOCABULARY_COLLECTION_CREATE", nil);
        } else {
            Collection *collection = [self.collections objectAtIndex:indexPath.row];
            
            static NSString *CellIdentifier = @"Name Desc Count";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
                cell.textLabel.text = collection.name; 
                cell.detailTextLabel.text = collection.desc; 
            } else {
                UILabel *nameLabel = ((UILabel *)([cell viewWithTag:20]));
                nameLabel.text = collection.name;
                
                
                CGRect tempFrame = nameLabel.frame;
                int cellHeight = cell.frame.size.height;
                int labelHeight = nameLabel.frame.size.height;
                int newYOrigin = (cellHeight / 2) - (labelHeight / 2);
               
                if (![collection.desc length]) {
                    tempFrame.origin = CGPointMake(tempFrame.origin.x, newYOrigin);
                } else {
                    tempFrame.origin = CGPointMake(tempFrame.origin.x, 4);
                }
                nameLabel.frame = tempFrame;
            
                ((UILabel *)([cell viewWithTag:21])).text = collection.desc;
                ((UILabel *)([cell viewWithTag:22])).text = [NSString stringWithFormat:@"%i", [collection.exercises count]];
            }
        }
    }
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}


- (void)    tableView:(UITableView *)tableView 
   commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
    forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        Collection *collection = [self.collections objectAtIndex:indexPath.row];
        [[DictVocTrainer instance] deleteCollection:collection];
        
        [self.collections removeObject:collection];
        if ([self.collections count] < 1) {
            [self initRightNavigationItemBar];
        }
        
        if ([self.collections count] > 0) {
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        } else {
            if (self.tableView.editing) {
                [self.tableView setEditing:NO animated:YES];
            }
            [self.tableView reloadData];
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing) {
        [self performSegueWithIdentifier:@"Show Collection Detail" sender:indexPath];
    } else if ([self.collections count]) {
        [self performSegueWithIdentifier:@"Show Collection" sender:indexPath];
    } else {
        [self performSegueWithIdentifier:@"Show Collection Detail" sender:nil];
    }
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing) {
        [self performSegueWithIdentifier:@"Show Collection Detail" sender:indexPath];
    }
}

@end
