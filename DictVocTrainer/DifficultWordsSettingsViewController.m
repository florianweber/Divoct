//
//  DifficultWordsSettingsViewController.m
//  Divoct
//
//  Created by Florian Weber on 09.10.12.
//  Copyright (c) 2012 IBM. All rights reserved.
//

#import "DifficultWordsSettingsViewController.h"
#import "GlobalDefinitions.h"

@interface DifficultWordsSettingsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;

@end

@implementation DifficultWordsSettingsViewController


- (void)loadDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *perfectSuccessRateKey = DVT_PERFECT_SUCCESSRATE_SETTING;
    NSNumber *perfectSuccessRateSetting = (NSNumber *)[defaults objectForKey:perfectSuccessRateKey];
    
    int currentSetting;
    if (perfectSuccessRateSetting) {
        currentSetting = perfectSuccessRateSetting.intValue;
    } else {
        currentSetting = DVT_DEFAULT_PERFECT_SUCCESSRATE;
    }
    
    self.numberLabel.text = [NSString stringWithFormat:@"%d", currentSetting];
    self.stepper.value = currentSetting;
}

- (IBAction)stepperValueChanged:(UIStepper *)sender {
    
    int stepperValue = (int)[sender value];
    self.numberLabel.text = [NSString stringWithFormat:@"%d", stepperValue];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *perfectSuccessRateKey = DVT_PERFECT_SUCCESSRATE_SETTING;
    [defaults setObject:[NSNumber numberWithInt:stepperValue] forKey:perfectSuccessRateKey];
    [defaults synchronize];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadDefaults];
}

- (void)viewDidUnload {
    [self setNumberLabel:nil];
    [self setStepper:nil];
    [super viewDidUnload];
}
@end
