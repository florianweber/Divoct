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

@end

@implementation PickerViewController
@synthesize pickList = _pickList;
@synthesize preselectedRow = _preselectedRow;

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


#pragma mark - My messages


#pragma mark - Target / Action

- (IBAction)cancelButtonPressed:(id)sender {
    [self.delegate pickerViewController:self pickedValue:nil];
}


- (IBAction)pickButtonPressed:(id)sender {
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
    
    [self.pickerView selectRow:self.preselectedRow inComponent:0 animated:NO];
    
    self.pickedItem = [self pickerView:self.pickerView titleForRow:[self.pickerView selectedRowInComponent:0] forComponent:0];
}

- (void)viewDidUnload
{
    [self setPickerView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
