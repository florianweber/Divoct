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
#import "DictVocSettings.h"

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
    int perfectSuccessRate = [DictVocSettings instance].trainingPerfectSuccessRate;
    self.numberLabel.text = [NSString stringWithFormat:@"%d", perfectSuccessRate];
    self.stepper.value = perfectSuccessRate;
    
    //Warn for well-known words only
    self.wellKnownWarningSwitch.on = [DictVocSettings instance].trainingWarnWellKnownOnly;
}

- (IBAction)stepperValueChanged:(UIStepper *)sender {
    
    int stepperValue = (int)[sender value];
    self.numberLabel.text = [NSString stringWithFormat:@"%d", stepperValue];
    
    [DictVocSettings instance].trainingPerfectSuccessRate = stepperValue;
}

- (IBAction)wellKnownWarningSwitchChanged:(UISwitch *)sender {
    [DictVocSettings instance].trainingWarnWellKnownOnly = sender.on;
}

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        [[self navigationController] popViewControllerAnimated:YES];
    }
}

-(void)addSwipeGestureRecognizer
{
    UISwipeGestureRecognizer *rightSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(handleSwipeFrom:)];
    rightSwiper.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwiper];
}

-(void)showHelp
{
    [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_SETTINS_DIFFICULT_WORDS", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addSwipeGestureRecognizer];
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
    if (self.scrollView.contentSize.height > self.scrollView.frame.size.height) {
        [self.scrollView flashScrollIndicators];
    }
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}
@end
