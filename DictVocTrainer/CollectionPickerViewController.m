//
//  CollectionPickerTableViewController.m
//  Divoct
//
//  Created by Florian Weber on 06.10.12.
//  Copyright (c) 2012 IBM. All rights reserved.
//

#import "CollectionPickerViewController.h"
#import "DictVocTrainer.h"
#import "Logging.h"
#import "GlobalDefinitions.h"
#import "FWToastView.h"

@interface CollectionPickerViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *allCollections;
@property (nonatomic) BOOL needsReload;
@property (nonatomic, strong) UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbarBottom;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *noneBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *allBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *counterBarButtonItem;


@end

@implementation CollectionPickerViewController

@synthesize allCollections = _collections;
@synthesize selectedCollections = _selectedCollections;
@synthesize needsReload = _needsReload;
@synthesize tableView = _tableView;
@synthesize countLabel = _countLabel;
@synthesize toolbarBottom = _toolbarBottom;
@synthesize noneBarButtonItem = _noneButton;
@synthesize allBarButtonItem = _allButton;

#pragma mark - Getter / Setter

-(UILabel *)countLabel
{
    if (!_countLabel) {
        _countLabel = [[UILabel alloc] init];
        _countLabel.font = [UIFont systemFontOfSize:16];
        _countLabel.backgroundColor = [UIColor clearColor];
        _countLabel.textColor = [UIColor whiteColor];
        _countLabel.textAlignment = UITextAlignmentLeft;
        _countLabel.numberOfLines = 1;
        _countLabel.lineBreakMode = UILineBreakModeTailTruncation;
        _countLabel.minimumFontSize = 6;
        _countLabel.adjustsFontSizeToFitWidth = YES;
        _countLabel.userInteractionEnabled = NO;
    }
    return _countLabel;
}

-(NSMutableSet *)selectedCollections {
    if (!_selectedCollections) {
        _selectedCollections = [NSMutableSet set];
    }
    return _selectedCollections;
}


#pragma mark - My Messages

-(void)initCountBarButtonItem
{
    int maxHeight = self.toolbarBottom.frame.size.height;
    int maxWidth = self.toolbarBottom.frame.size.width - self.allBarButtonItem.width - self.noneBarButtonItem.width - 34;
    
    CGRect labelFrame = CGRectMake(4, 0, maxWidth, maxHeight);
    self.countLabel.frame = labelFrame;
    
    [self.counterBarButtonItem setCustomView:self.countLabel];
    [self updateCountLabel];
}

-(void)updateCountLabel
{
    int countCollections = [self.selectedCollections count];
    
    NSMutableSet *distinctExercises = [NSMutableSet set];
    for (Collection *collection in self.selectedCollections) {
        [distinctExercises addObjectsFromArray:collection.exercises.array];
    }
    
    int countExercises = distinctExercises.count;
    
    self.countLabel.text = [NSString stringWithFormat:@"%i %@ / %i %@ %@", countCollections, (countCollections != 1) ? NSLocalizedString(@"COLLECTION_PICKER_COUNT_P1_PL", nil) : NSLocalizedString(@"COLLECTION_PICKER_COUNT_P1_SL", nil), countExercises, (countExercises != 1) ? NSLocalizedString(@"COLLECTION_PICKER_COUNT_P2_PL", nil) : NSLocalizedString(@"COLLECTION_PICKER_COUNT_P2_SL", nil), NSLocalizedString(@"COLLECTION_PICKER_COUNT_P3", nil)];

}

-(void)loadContents
{
    self.allCollections = [[[DictVocTrainer instance] allCollections] mutableCopy];
}

-(void)switchCheckmarkInCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self.selectedCollections addObject:self.allCollections[indexPath.row]];
    } else if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        for (Collection *collection in self.selectedCollections) {
            if ([collection.name isEqualToString:((UILabel *)([cell viewWithTag:20])).text]) {
                [self.selectedCollections removeObject:collection];
                break;
            }
        }
    }
    [self updateCountLabel];
}

-(void)showHelp
{
    [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_COLLECTION_PICKER", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES forceLandscape:UIInterfaceOrientationIsLandscape(self.interfaceOrientation)];
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

- (IBAction)cancelButtonPressed:(id)sender {
    [self.delegate collectionPickerViewController:self pickedCollections:nil];
}

- (IBAction)pickButtonPressed:(id)sender {
    [self.delegate collectionPickerViewController:self pickedCollections:self.selectedCollections];
}

- (IBAction)allButtonPressed:(id)sender {
    [self.selectedCollections removeAllObjects];
    [self.selectedCollections addObjectsFromArray:self.allCollections];
    [self.tableView reloadData];
    [self updateCountLabel];
}

- (IBAction)noneButtonPressed:(id)sender {
    [self.selectedCollections removeAllObjects];
    [self.tableView reloadData];
    [self updateCountLabel];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    [self initCountBarButtonItem];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(collectionInserted:) name:DVT_COLLECTION_NOTIFICATION_INSERTED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(collectionDeleted:) name:DVT_COLLECTION_NOTIFICATION_DELETED object:nil];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self initCountBarButtonItem];
}


- (void)viewDidUnload {
    [self setTableView:nil];
    [self setToolbarBottom:nil];
    [self setNoneBarButtonItem:nil];
    [self setAllBarButtonItem:nil];
    [self setCounterBarButtonItem:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.allCollections count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Collection *collection = [self.allCollections objectAtIndex:indexPath.row];
    
    static NSString *CellIdentifier = @"Name Desc Count";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        
        if ([collection.name isEqualToString:NSLocalizedString(@"RECENTS_TITLE", nil)]) {
            cell.textLabel.text = NSLocalizedString(@"RECENTS_DISPLAY_TITLE", nil);
            cell.detailTextLabel.text = NSLocalizedString(@"RECENTS_DESC", nil);
        } else {
            cell.textLabel.text = collection.name;
            cell.detailTextLabel.text = collection.desc;
        }
        
    } else {
        //set labels
        UILabel *nameLabel = ((UILabel *)([cell viewWithTag:20]));
        UILabel *descLabel = ((UILabel *)([cell viewWithTag:21]));
        UILabel *countLabel = ((UILabel *)([cell viewWithTag:22]));
        
        if ([collection.name isEqualToString:NSLocalizedString(@"RECENTS_TITLE", nil)]) {
            nameLabel.text = NSLocalizedString(@"RECENTS_DISPLAY_TITLE", nil);
            descLabel.text = NSLocalizedString(@"RECENTS_DESC", nil);
        } else {
            nameLabel.text = collection.name;
            descLabel.text = collection.desc;
        }
        countLabel.text = [NSString stringWithFormat:@"%i", [collection.exercises count]];
        
        //reposition labels if necessary
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
    }

    if ([self.selectedCollections containsObject:collection]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self switchCheckmarkInCellAtIndexPath:indexPath];
}

@end
