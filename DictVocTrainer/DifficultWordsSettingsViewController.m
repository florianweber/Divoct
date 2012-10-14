//
//  DifficultWordsSettingsViewController.m
//  Divoct
//
//  Created by Florian Weber on 09.10.12.
//  Copyright (c) 2012 IBM. All rights reserved.
//

#import "DifficultWordsSettingsViewController.h"
#import "GlobalDefinitions.h"
#import "FWToastView.h"

@interface DifficultWordsSettingsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UISwitch *wellKnownWarningSwitch;

@end

@implementation DifficultWordsSettingsViewController


- (void)loadDefaults
{
    //Success rate amount
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
    
    //Warn for well-known words only
    NSString *warnForWellKnownOnlyKey = DVT_NSUSERDEFAULTS_WARN_WELLKNOWN_ONLY;
    NSNumber *warnForWellKnownOnlyMode = (NSNumber *)[defaults objectForKey:warnForWellKnownOnlyKey];
    if (warnForWellKnownOnlyMode) {
        self.wellKnownWarningSwitch.on = [warnForWellKnownOnlyMode boolValue];
    } else {
        switch (DVT_DEFAULT_WARN_WELLKNOWN_ONLY) {
            case 0:
                self.wellKnownWarningSwitch.on = NO;
                break;
                
            case 1:
                self.wellKnownWarningSwitch.on = YES;
                break;
                
            default:
                self.wellKnownWarningSwitch.on = NO;
                break;
        }
        ;
    }
}

- (IBAction)stepperValueChanged:(UIStepper *)sender {
    
    int stepperValue = (int)[sender value];
    self.numberLabel.text = [NSString stringWithFormat:@"%d", stepperValue];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *perfectSuccessRateKey = DVT_PERFECT_SUCCESSRATE_SETTING;
    [defaults setObject:[NSNumber numberWithInt:stepperValue] forKey:perfectSuccessRateKey];
    [defaults synchronize];
}

- (IBAction)wellKnownWarningSwitchChanged:(UISwitch *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *warnForWellKnownOnlyKey = DVT_NSUSERDEFAULTS_WARN_WELLKNOWN_ONLY;
    
    if (sender.on) {
        //set to case insensitive
        [defaults setObject:[NSNumber numberWithInt:1] forKey:warnForWellKnownOnlyKey];
    } else {
        //set to case sensitive
        [defaults setObject:[NSNumber numberWithInt:0] forKey:warnForWellKnownOnlyKey];
    }
    
    [defaults synchronize];
}

-(void)showHelp
{
    [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_SETTINS_DIFFICULT_WORDS", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
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
    
    self.scrollView.contentSize = CGSizeMake(320, 440);
    
    if (self.scrollView.contentSize.height > self.scrollView.frame.size.height) {
        [self.scrollView flashScrollIndicators];
    }

}

- (void)viewDidUnload {
    [self setNumberLabel:nil];
    [self setStepper:nil];
    [self setScrollView:nil];
    [self setWellKnownWarningSwitch:nil];
    [super viewDidUnload];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (self.scrollView.contentSize.height > self.scrollView.frame.size.height) {
        [self.scrollView flashScrollIndicators];
    }
}
@end
