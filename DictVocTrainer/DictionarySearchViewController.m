/*
DictionarySearchViewController.m
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


#import "DictionarySearchViewController.h"
#import "DictVocDictionary.h"
#import "GlobalDefinitions.h"
#import "LoadingViewController.h"
#import "Logging.h"
#import "NormalizedStringTransformer.h"
#import "SQLiteWord.h"
#import "VocabularyDetailViewController.h"
#import "FWToastView.h"
#import "DictVocTrainer.h"
#import "DictVocSettings.h"

static BOOL L0AccelerationIsShaking(UIAcceleration* last, UIAcceleration* current, double threshold) {
    double
    deltaX = fabs(last.x - current.x),
    deltaY = fabs(last.y - current.y),
    deltaZ = fabs(last.z - current.z);
    
    return
    (deltaX > threshold && deltaY > threshold) ||
    (deltaX > threshold && deltaZ > threshold) ||
    (deltaY > threshold && deltaZ > threshold);
}

@interface DictionarySearchViewController() <LoadingViewControllerDelegate, UISearchBarDelegate, UIAccelerometerDelegate, UITabBarControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchModeButton;
@property (nonatomic, strong) DictVocDictionary *dictVocDictionary;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) NSArray *currentSearchResults; //of SQLiteWordsp
@property (nonatomic, strong) NSArray *unfilteredSearchResults;
@property (nonatomic, strong) NSString *currentSearchTerm;
@property (nonatomic, strong) NSTimer *searchTimer;
@property (nonatomic, strong) NSIndexPath *lastSelectedIndexPath;
@property (nonatomic, strong) UIAcceleration* lastAcceleration;
@property (nonatomic) BOOL histeresisExcited;

@end


@implementation DictionarySearchViewController
@synthesize searchModeButton = _searchModeButton;
@synthesize dictVocDictionary = _dictVocDictionary;
@synthesize searchBar = _searchBar;
@synthesize activityIndicator = _activityIndicator;
@synthesize currentSearchResults = _currentSearchResults;
@synthesize currentSearchTerm = _currentSearchTerm;
@synthesize unfilteredSearchResults = _unfilteredSearchResults;
@synthesize searchTimer = _searchTimer;
@synthesize lastSelectedIndexPath = _lastSelectedIndexPath;
@synthesize lastAcceleration = _lastAcceleration;
@synthesize histeresisExcited = _histeresisExcited;


#pragma mark - Getter / Setter

- (DictVocDictionary *)dictVocDictionary 
{
    if (!_dictVocDictionary) {
        _dictVocDictionary = [DictVocDictionary instance];
    }
    return _dictVocDictionary;
}

- (UIActivityIndicatorView *)activityIndicator
{
    if (!_activityIndicator) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self.activityIndicator setHidesWhenStopped:YES];
        [self.activityIndicator stopAnimating];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_activityIndicator];
    }
    return _activityIndicator;
}


#pragma mark - My messages

//as the database search doesn't differentiate case, we have to filter the results afterwards
-(void)filterCurrentSearchResults
{
    NSPredicate *filter;
    switch ([DictVocSettings instance].searchMode) {
        case DictionarySearchMode_TermBeginsWithCaseSensitive:
            filter = [NSPredicate predicateWithFormat:@"name contains %@", self.currentSearchTerm];
            break;
            
        case DictionarySearchMode_TermBeginsWithCaseInsensitive:
            filter = [NSPredicate predicateWithFormat:@"name contains[c] %@", self.currentSearchTerm];
            break;
            
        default:
            break;
    }
    self.currentSearchResults = [self.unfilteredSearchResults filteredArrayUsingPredicate:filter];
}

-(void)sortCurrentSearchResults
{
    int searchResultCount = [self.currentSearchResults count];
    NSArray *arrayToSort;
    if (searchResultCount) {
        arrayToSort = self.currentSearchResults;
    } else {
        arrayToSort = self.unfilteredSearchResults;
    }
    
    //sort is an expensive operation, so we will only sort the results if < DVT_MAX_RESULTS_TO_SORT
    if ([arrayToSort count] < DVT_MAX_RESULTS_TO_SORT) {
    
        //sort by length
        self.currentSearchResults = [arrayToSort sortedArrayUsingComparator:^(id a, id b) {
            int firstLength = [((SQLiteWord *)a).nameWithoutContextInfo length];
            int secondLength = [((SQLiteWord *)b).nameWithoutContextInfo length];
            return firstLength >= secondLength;
        }];
        
        //sort by case match (beispiel garten)
        if ([DictVocSettings instance].searchMode == DictionarySearchMode_TermBeginsWithCaseInsensitive) {
            self.currentSearchResults = [self.currentSearchResults sortedArrayUsingComparator:^(id a, id b) {
                
                if ([((SQLiteWord *)a).name rangeOfString:self.currentSearchTerm].location != NSNotFound) {
                    return (NSComparisonResult)NSOrderedAscending;
                } else if ([((SQLiteWord *)b).name rangeOfString:self.currentSearchTerm].location != NSNotFound) {
                    return (NSComparisonResult)NSOrderedDescending;
                } else {
                    return (NSComparisonResult)NSOrderedSame;
                }
            }];
        }
    }
}

-(void)searchWordsBeginningWithTerm:(NSString *)term
{
    LogDebug("Searching for: %@", term);
    self.lastSelectedIndexPath = nil;
    [self.activityIndicator startAnimating];
    self.currentSearchTerm = [term copy];
    [self.dictVocDictionary getWordsBeginningWithTerm:self.currentSearchTerm
                                   withRelationsships:NO
                                           usingBlock:^(NSString *searchTerm, NSArray *sqliteResults){
                                               if ([searchTerm isEqualToString:self.currentSearchTerm]) {
                                                   self.unfilteredSearchResults = sqliteResults;
                                                   [self filterCurrentSearchResults];
                                                   [self sortCurrentSearchResults];
                                                   [self.tableView reloadData];
                                                   [self.activityIndicator stopAnimating];
                                               }
                                           }];
}

-(void)searchWordsWithTimer:(NSTimer *)timer
{
    NSDictionary *timerInfo = [timer userInfo];
    NSString *searchTerm = [timerInfo objectForKey:@"SEARCHTEXT"];
    [self searchWordsBeginningWithTerm:searchTerm];
}

-(void)resetSearchResults
{
    self.lastSelectedIndexPath = nil;
    [self.activityIndicator stopAnimating];
    self.currentSearchResults = nil;
    [self.tableView reloadData];
}

-(void)disableTabbar
{
    
}

-(void)addSwipeGestureRecognizer
{
    UISwipeGestureRecognizer *leftSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                                     action:@selector(handleSwipeFrom:)];
    leftSwiper.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:leftSwiper];
}

-(void)furtherViewDidLoadSetup
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchModeChanged:) name:DVT_SETTINGS_NOTIFICATION_SEARCHCASESWITCHED object:nil];
    [self addSwipeGestureRecognizer];
    
    [UIAccelerometer sharedAccelerometer].delegate = self;
}

-(void)showHelp 
{
    [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_SEARCH", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES pointingToView:self.searchBar fromDirection:FWToastViewPointingFromDirectionBottom];
    [self.tableView scrollRectToVisible:self.view.frame animated:YES];
    
}


#pragma mark - Search Bar delegate

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.searchTimer invalidate];
    self.searchTimer = nil;
    
    NSString *searchString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (![searchString length]) {
        [self resetSearchResults];
    } else {
        int lengthToStartSearch = DVT_STARTSEARCH_WITH_LENGTH;
        int normalizedSearchStringLength = [searchString length];
        
        if ([searchString hasPrefix:@"to "]) {
            normalizedSearchStringLength -= 1;
        }
        
        if (normalizedSearchStringLength < lengthToStartSearch) {
            [self.activityIndicator stopAnimating];
        } else if (normalizedSearchStringLength >= lengthToStartSearch) {
            
            NSDictionary *timerInfo = [NSDictionary dictionaryWithObjectsAndKeys:searchText, @"SEARCHTEXT", nil];
            
            NSTimeInterval waitFor = DVT_WAITSECONDS_FOR_USER_INPUT;
            self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:waitFor
                                                                target:self
                                                              selector:@selector(searchWordsWithTimer:)
                                                              userInfo:timerInfo
                                                               repeats:NO];
        }
     
    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar 
{
    [self.searchTimer invalidate];
    self.searchTimer = nil;
    
    NSString *searchString = [searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([searchString length]) {
        if (![searchString isEqualToString:self.currentSearchTerm]) {
            [self searchWordsBeginningWithTerm:searchString];
        }
    } else {
        [self resetSearchResults];
    }
    
    [self.searchBar resignFirstResponder];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar resignFirstResponder];
}

#pragma mark - Navigation Controller Delegate

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Vocabulary Details"]) {
        
        SQLiteWord *word = [self.currentSearchResults objectAtIndex:((NSIndexPath *)sender).row];
        Exercise *exercise = [[DictVocTrainer instance] exerciseWithWordUniqueId:word.uniqueId updateLastLookedUp:YES];
        [exercise addCollectionsObject:[[DictVocTrainer instance] collectionWithName:NSLocalizedString(@"RECENTS_TITLE", nil)]];
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:DVT_COLLECTION_NOTIFICATION_CONTENTS_CHANGED object:nil]];
        
        [segue.destinationViewController setExercise:exercise];
        [segue.destinationViewController setEditTrainingTranslationsButtonEnabled:YES];
    } 
}

#pragma mark - Target / Action

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        if (self.lastSelectedIndexPath) {
            [self performSegueWithIdentifier:@"Show Vocabulary Details" sender:self.lastSelectedIndexPath];
        }
    }
}


#pragma mark - Notifications

-(void)searchModeChanged:(NSNotification *)notification
{
    if ([self.currentSearchResults count] > 1) {
        [self filterCurrentSearchResults];
        [self sortCurrentSearchResults];
        [self.tableView reloadData];
    }
}

#pragma mark - UIAccelerator delegate
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    
    if (self.lastAcceleration) {
        if (!self.histeresisExcited && L0AccelerationIsShaking(self.lastAcceleration, acceleration, 1.0)) {
            self.histeresisExcited = YES;
            
            if (!(self.tabBarController.selectedIndex == 0)) {
                self.tabBarController.selectedIndex = 0;
            }
            
            if (!([self.navigationController topViewController] == self)) {
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
            
            if (!self.searchBar.isFirstResponder) {
                [self.tableView scrollRectToVisible:self.view.frame animated:YES];
                self.searchBar.text = @"";
                [self.searchBar becomeFirstResponder];
            }
            
        } else if (self.histeresisExcited && !L0AccelerationIsShaking(self.lastAcceleration, acceleration, 0.2)) {
            self.histeresisExcited = NO;
        }
    }
    
    self.lastAcceleration = acceleration;
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
    
    if ([self.dictVocDictionary firstTimeSetupRequired]) {
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
        [self.dictVocDictionary setupDatabaseWithCompletionBlock:^(NSError *error){
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
        [self.activityIndicator startAnimating];
        [self.searchBar setHidden:YES];
        
        //init dictionary database
        NSError *error = [self.dictVocDictionary openDatabaseWithFileName:DVT_DB_FILE_NAME];
        if (error) {
            [self.activityIndicator stopAnimating];
            LoadingViewController *loadingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Loading View"];
            loadingViewController.text = [error localizedDescription];
            [self.tabBarController presentViewController:loadingViewController animated:YES completion:nil];
        } else {
            //init training database
            [[DictVocTrainer instance] openDictVocTrainerDBUsingBlock:^(NSError *error) {
                if (error) {
                    LoadingViewController *loadingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Loading View"];
                    loadingViewController.text = [error localizedDescription];
                    [self.tabBarController presentViewController:loadingViewController animated:YES completion:nil];
                } else {
                    [self furtherViewDidLoadSetup];
                    [self.activityIndicator stopAnimating];
                    [self.searchBar setHidden:NO];
                }
            }];
        }
    }
}

- (void)viewDidUnload {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[DictVocTrainer instance] saveDictVocTrainerDBUsingBlock:^(NSError *error) {
        if (error) {
            LoadingViewController *loadingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Loading View"];
            loadingViewController.text = [error localizedDescription];
            [self.tabBarController presentViewController:loadingViewController animated:YES completion:nil];
        } else {
            [[DictVocTrainer instance] closeDictVocTrainerDBUsingBlock:^(NSError *error) {
                if (error) {
                    LoadingViewController *loadingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Loading View"];
                    loadingViewController.text = [error localizedDescription];
                    [self.tabBarController presentViewController:loadingViewController animated:YES completion:nil];
                }
            }];
        }
    }];
    
    [self setSearchBar:nil];
    [self setDictVocDictionary:nil];
    [self setSearchModeButton:nil];
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.currentSearchResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SQLiteWord *word = [self.currentSearchResults objectAtIndex:indexPath.row];
    
    static NSString *CellIdentifier = @"Dictionary Word Search Result - Right Image";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.textLabel.text = word.name;
        cell.detailTextLabel.text = word.language;
    } else {
        ((UILabel *)([cell viewWithTag:10])).text = word.name;
        switch ([word.languageCode intValue]) {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchBar resignFirstResponder];
    
    [self performSegueWithIdentifier:@"Show Vocabulary Details" sender:indexPath];
    self.lastSelectedIndexPath = indexPath;
}




@end
