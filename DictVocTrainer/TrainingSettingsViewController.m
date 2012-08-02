//
//  TrainingSettingsViewController.m
//  Divoct
//
//  Created by Florian Weber on 26.07.12.
//  Copyright (c) 2012 IBM. All rights reserved.
//

#import "TrainingSettingsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "TrainingViewController.h"
#import "Exercise+Extended.h"
#import "SQLiteWord.h"
#import "DictVocDictionary.h"
#import "DictVocTrainer.h"
#import "FWToastView.h"
#import "MOGlassButton.h"
#include <stdlib.h>

@interface TrainingSettingsViewController ()

@property (nonatomic, strong) NSMutableArray *exercises;
@property (nonatomic, strong) NSString *trainingTitle;
@property (weak, nonatomic) IBOutlet MOGlassButton *tenButton;
@property (weak, nonatomic) IBOutlet MOGlassButton *twentyFiveButton;
@property (weak, nonatomic) IBOutlet MOGlassButton *fiftyButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *modeSelectionControl;
@property (weak, nonatomic) IBOutlet MOGlassButton *allButton;
@property (weak, nonatomic) IBOutlet MOGlassButton *randomButton;
@property (weak, nonatomic) IBOutlet MOGlassButton *difficultButton;

@end

@implementation TrainingSettingsViewController

@synthesize collection = _collection;
@synthesize exercises = _exercises;
@synthesize trainingTitle = _trainingTitle;
@synthesize tenButton = _TenButton;
@synthesize twentyFiveButton = _TwentyFiveButton;
@synthesize fiftyButton = _FiftyButton;
@synthesize modeSelectionControl = _modeSelectionControl;
@synthesize allButton = _allButton;
@synthesize randomButton = _randomButton;
@synthesize difficultButton = _difficultButton;


#pragma mark - Init


#pragma mark - Getter / Setter


#pragma mark - My messages

- (void)configureButtons
{
    [self.allButton setupAsDarkGrayButton];
    [self.randomButton setupAsDarkGrayButton];
    [self.difficultButton setupAsDarkGrayButton];
    
    [self.tenButton setupAsDarkGrayButton];
    [self.twentyFiveButton setupAsDarkGrayButton];
    [self.fiftyButton setupAsDarkGrayButton];
    
    
    if (self.collection.exercises.count < 10) {
        self.tenButton.enabled = NO;
        self.twentyFiveButton.enabled = NO;
        self.fiftyButton.enabled = NO;
    } else if ((self.collection.exercises.count >= 10) && (self.collection.exercises.count < 25)) {
        self.twentyFiveButton.enabled = NO;
        self.fiftyButton.enabled = NO;
    } else if ((self.collection.exercises.count >= 25) && (self.collection.exercises.count < 50)) {
        self.fiftyButton.enabled = NO;  
    } else {
        self.tenButton.enabled = YES;
        self.twentyFiveButton.enabled = YES;
        self.fiftyButton.enabled = YES;
    }
}

-(void)createExercises:(int)count
{
    //create self.exercises
    self.exercises = [NSMutableArray arrayWithCapacity:count];
    
    //copy all available exercises and reduce this new array by the amount of count
    NSMutableArray *availableExercises = [self.collection.exercises mutableCopy];
    
    int randomIndex;
    int upperBoundIndex;
    while (count > 0) {
        upperBoundIndex = [availableExercises count] - 1;
        randomIndex = arc4random_uniform(upperBoundIndex);
        [self.exercises addObject:[availableExercises objectAtIndex:randomIndex]];
        [availableExercises removeObjectAtIndex:randomIndex];
        count--;
    }
}

-(void)startTraining:(NSNumber *)trainingCode
{
    //set training title
    if ([self.collection.name isEqualToString:NSLocalizedString(@"RECENTS_TITLE", nil)]) {
        self.trainingTitle = NSLocalizedString(@"RECENTS_DISPLAY_TITLE", nil);
    } else {
        self.trainingTitle = self.collection.name;
    }
    
    NSNumber *trainingMode;
    if (self.modeSelectionControl.selectedSegmentIndex == 0) {
        trainingMode = [NSNumber numberWithInt:TrainingMode_Buttons];
    } else if (self.modeSelectionControl.selectedSegmentIndex == 1) {
        trainingMode = [NSNumber numberWithInt:TrainingMode_TextInput];
    }
    
    NSDictionary *trainingSettings = [NSDictionary dictionaryWithObjectsAndKeys:trainingMode, @"trainingMode", trainingCode, @"trainingCode", nil];
    
    [self performSegueWithIdentifier:@"Show Training" sender:trainingSettings];
}

-(void)showHelp
{
    //todo
    //[FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_TRAINING_QUESTIONS", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
}

#pragma mark - Target / Action

- (IBAction)trainCompleteCollectionButtonPressed:(id)sender {
    [self startTraining:[NSNumber numberWithInt:0]];
}

- (IBAction)trainTenWordsButtonPressed:(id)sender {
    
    //create exercises (if necessary)
    if (self.collection.exercises.count > 10) {
        [self createExercises:10];
    }
    
    //start training
    [self startTraining:[NSNumber numberWithInt:1]];
}

- (IBAction)trainTwentyFiveWordsButtonPressed:(id)sender {

    //create exercises (if necessary)
    if (self.collection.exercises.count > 25) {
        [self createExercises:25];
    }
    
    //start training
    [self startTraining:[NSNumber numberWithInt:2]];
}

- (IBAction)trainFiftyWordsButtonPressed:(id)sender {

    //create exercises (if necessary)
    if (self.collection.exercises.count > 50) {
        [self createExercises:50];
    }
    
    //start training
    [self startTraining:[NSNumber numberWithInt:3]];
}

- (IBAction)trainRandomNumberOfWordsButtonPressed:(id)sender {
    int randomCount = arc4random_uniform(self.collection.exercises.count - 1);
    
    if (randomCount <= 0) {
        randomCount = 1;
    }
    
    //create exercises (if necessary)
    [self createExercises:randomCount];
    
    //start training
    [self startTraining:[NSNumber numberWithInt:4]];
}

- (IBAction)trainDifficultWordsButtonPressed:(id)sender {
    
    NSNumber *sumOfSuccessRates = [NSNumber numberWithFloat:0.0];
    NSNumber *exerciseCount = [NSNumber numberWithUnsignedInteger:self.collection.exercises.count];
    for (Exercise *exercise in self.collection.exercises) {
        sumOfSuccessRates = [NSNumber numberWithFloat:(sumOfSuccessRates.floatValue + exercise.successRate.floatValue)];
    }
    NSNumber *average = [NSNumber numberWithFloat:(sumOfSuccessRates.floatValue / exerciseCount.floatValue)];
    
    self.exercises = [NSMutableArray array];
    if (average.floatValue < 1.0) {
        //if average is lower than 1.0, exercise all words with successrate <= 1.0
        for (Exercise *exercise in self.collection.exercises) {
            if (exercise.successRate.floatValue <= 1.0) {
                [self.exercises addObject:exercise];
            }
        }
    } else {
        //if average is higher than or equal to 1.0, exercise all words with successrate <= the average
        for (Exercise *exercise in self.collection.exercises) {
            if (exercise.successRate.floatValue <= average.floatValue) {
                [self.exercises addObject:exercise];
            }
        }
    }
    
    [self startTraining:[NSNumber numberWithInt:5]];
    
}



#pragma mark - Search Bar delegate


#pragma mark - Navigation Controller Delegate

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Training"]) {
        int trainingCode = ((NSNumber *)[((NSDictionary *)sender) objectForKey:@"trainingCode"]).intValue;
        TrainingMode trainingMode = ((NSNumber *)[((NSDictionary *)sender) objectForKey:@"trainingMode"]).intValue;
        
        //set training mode (buttons or text input atm)
        [segue.destinationViewController setTrainingMode:trainingMode];
        
        //depending on training code, set whole collection or exercises
        if (trainingCode == 0) {
            //full collection
            [segue.destinationViewController setCollection:self.collection];
            
        } else {
            //only part of collection
            [segue.destinationViewController setExercisesInput:self.exercises];
            [segue.destinationViewController setTrainingTitle:self.trainingTitle];
        }
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self configureButtons];
}

- (void)viewDidUnload
{
    [self setModeSelectionControl:nil];
    [self setAllButton:nil];
    [self setRandomButton:nil];
    [self setDifficultButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
@end
