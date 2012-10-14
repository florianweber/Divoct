//
//  PickerViewController.m
//  Divoct
//
//  Created by Florian Weber on 09.08.12.
//  Copyright (c) 2012 IBM. All rights reserved.
//

#import "PickerViewController.h"

@interface PickerViewController () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (nonatomic, strong) NSString *pickedItem;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *selectionDescriptionLabel;

@end

@implementation PickerViewController
@synthesize descriptionLabel = _descriptionLabel;
@synthesize selectionDescriptionLabel = _selectionDescriptionLabel;
@synthesize pickList = _pickList;
@synthesize preselectedRow = _preselectedRow;
@synthesize description = _description;

#pragma mark - Init
@synthesize pickerView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark - Getter / Setter

- (void)setDescription:(NSString *)description
{
    if(description) {
        _description = description;
        [self.descriptionLabel setText:description];
    }
}

#pragma mark - My messages

- (void)layoutViews
{
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        self.descriptionLabel.frame = CGRectMake(0, 48, [UIScreen mainScreen].bounds.size.height, 15);
        self.selectionDescriptionLabel.frame = CGRectMake(0, 66, [UIScreen mainScreen].bounds.size.height, 15);
        self.selectionDescriptionLabel.numberOfLines = 1;
    } else {
        self.descriptionLabel.frame = CGRectMake(20, 60, 280, 76);
        self.selectionDescriptionLabel.frame = CGRectMake(20, 140, 280, 80);
        self.selectionDescriptionLabel.numberOfLines = 4;
    }
}

- (void)updateSelectionDescriptionForRow:(NSInteger)row
{
    NSString* selectionTitle = [self pickerView:self.pickerView titleForRow:row forComponent:0];
    
    NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *numberOfWords = [numberFormatter numberFromString:selectionTitle];
    
    if (numberOfWords) {
        self.selectionDescriptionLabel.text = [NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_DESC_NUM_1", nil), selectionTitle,  NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_DESC_NUM_2", nil)];
    } else {
        //All
        if (selectionTitle == NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_ALL", nil)) {
            self.selectionDescriptionLabel.text = NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_DESC_ALL", nil);
            //Random
        } else if (selectionTitle == NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_RAND", nil)) {
            self.selectionDescriptionLabel.text = NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_DESC_RAND", nil);
            //Difficult
        } else if (selectionTitle == NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_DIFF", nil)) {
            self.selectionDescriptionLabel.text = NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_DESC_DIFF", nil);
        } else {
            self.selectionDescriptionLabel.text = @"";
        }
    }
}

#pragma mark - Target / Action

- (IBAction)cancelButtonPressed:(id)sender {
    [self.delegate pickerViewController:self pickedValue:nil];
}


- (IBAction)pickButtonPressed:(id)sender {
    NSInteger row = [self.pickerView selectedRowInComponent:0];
    self.pickedItem = [self.pickList objectAtIndex:row];
    [self.delegate pickerViewController:self pickedValue:self.pickedItem];
}


#pragma mark - Picker View Controller Delegate & Datasource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.pickList.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.pickList objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.pickedItem = [self.pickList objectAtIndex:row];
    [self updateSelectionDescriptionForRow:row];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel* label = (UILabel*)view;
    if (view == nil){
        label= [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 260, 44)];
        
        label.textAlignment = UITextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont boldSystemFontOfSize:16];
    }
    label.text = [self.pickList objectAtIndex:row];
    return label;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    
    [self.descriptionLabel setText:self.description];
    
    [self.pickerView selectRow:self.preselectedRow inComponent:0 animated:NO];
    [self updateSelectionDescriptionForRow:self.preselectedRow];
    
    self.pickedItem = [self pickerView:self.pickerView titleForRow:self.preselectedRow forComponent:0];
    
    [self layoutViews];
}

- (void)viewDidUnload
{
    [self setPickerView:nil];
    [self setDescriptionLabel:nil];
    [self setSelectionDescriptionLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self layoutViews];
}

@end
