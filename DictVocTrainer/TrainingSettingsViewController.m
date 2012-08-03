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
#import "Training.h"
#include <stdlib.h>

@interface TrainingSettingsViewController ()

@property (weak, nonatomic) IBOutlet MOGlassButton *tenButton;
@property (weak, nonatomic) IBOutlet MOGlassButton *twentyFiveButton;
@property (weak, nonatomic) IBOutlet MOGlassButton *fiftyButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *modeSelectionControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *wrongAnswerHandlingControl;
@property (weak, nonatomic) IBOutlet MOGlassButton *allButton;
@property (weak, nonatomic) IBOutlet MOGlassButton *randomButton;
@property (weak, nonatomic) IBOutlet MOGlassButton *difficultButton;
@property (nonatomic, strong) Training *training;

@end

@implementation TrainingSettingsViewController

@synthesize tenButton = _TenButton;
@synthesize twentyFiveButton = _TwentyFiveButton;
@synthesize fiftyButton = _FiftyButton;
@synthesize modeSelectionControl = _modeSelectionControl;
@synthesize wrongAnswerHandlingControl = _wrongAnswerHandlingControl;
@synthesize allButton = _allButton;
@synthesize randomButton = _randomButton;
@synthesize difficultButton = _difficultButton;
@synthesize training = _training;


#pragma mark - Init


#pragma mark - Getter / Setter

-(void)setCollection:(Collection *)collection
{
    if(collection) {
        self.training = [[Training alloc] init];
        self.training.collection = collection;
    }
}


#pragma mark - My messages

- (void)configureButtons
{
    [self.allButton setupAsDarkGrayButton];
    [self.randomButton setupAsDarkGrayButton];
    [self.difficultButton setupAsDarkGrayButton];
    
    [self.tenButton setupAsDarkGrayButton];
    [self.twentyFiveButton setupAsDarkGrayButton];
    [self.fiftyButton setupAsDarkGrayButton];
    
    
    if (self.training.collection.exercises.count < 10) {
        self.tenButton.enabled = NO;
        self.twentyFiveButton.enabled = NO;
        self.fiftyButton.enabled = NO;
    } else if ((self.training.collection.exercises.count >= 10) && (self.training.collection.exercises.count < 25)) {
        self.twentyFiveButton.enabled = NO;
        self.fiftyButton.enabled = NO;
    } else if ((self.training.collection.exercises.count >= 25) && (self.training.collection.exercises.count < 50)) {
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
    self.training.exercises = [NSMutableArray arrayWithCapacity:count];
    
    //copy all available exercises and reduce this new array by the amount of count
    NSMutableArray *availableExercises = [self.training.collection.exercises mutableCopy];
    
    int randomIndex;
    int upperBoundIndex;
    while (count > 0) {
        upperBoundIndex = [availableExercises count] - 1;
        randomIndex = arc4random_uniform(upperBoundIndex);
        [self.training.exercises addObject:[availableExercises objectAtIndex:randomIndex]];
        [availableExercises removeObjectAtIndex:randomIndex];
        count--;
    }
}

-(void)startTraining:(NSNumber *)trainingCode
{
    //Answer Input Mode Selection
    if (self.modeSelectionControl.selectedSegmentIndex == 0) {
        self.training.trainingAnswerInputMode = TrainingAnswerInputMode_MultipleChoice;
    } else if (self.modeSelectionControl.selectedSegmentIndex == 1) {
        self.training.trainingAnswerInputMode = TrainingAnswerInputMode_TextInput;
    }
    
    //Wrong Answer Handling Mode Selection
    if (self.wrongAnswerHandlingControl.selectedSegmentIndex == 0) {
        self.training.trainingWrongAnswerHandlingMode = TrainingWrongAnswerHandlingMode_Repeat;
    } else if (self.wrongAnswerHandlingControl.selectedSegmentIndex == 1) {
        self.training.trainingWrongAnswerHandlingMode = TrainingWrongAnswerHandlingMode_Dismiss;
    }
    
    self.training.trainingResult = nil;
    self.training.trainingResultsObjectId = nil;

    [self performSegueWithIdentifier:@"Show Training" sender:self];
}

-(void)loadSavedSettings
{
    [self loadPreviousTrainingMode];
    
}

-(void)loadPreviousTrainingMode
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *trainingModeKey = DVT_NSUSERDEFAULTS_TRAININGMODE;
    NSNumber *userDefaultsTrainingMode = (NSNumber *)[defaults objectForKey:trainingModeKey];
    [self.modeSelectionControl setSelectedSegmentIndex:userDefaultsTrainingMode.integerValue];
}

-(void)loadPreviousWrongAnswerHandlingMode
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *wrongAnswerHandlingModeKey = DVT_NSUSERDEFAULTS_WRONGANSWERHANDLINGMODE;
    NSNumber *userDefaultsWrongAnswerHandlingMode = (NSNumber *)[defaults objectForKey:wrongAnswerHandlingModeKey];
    [self.wrongAnswerHandlingControl setSelectedSegmentIndex:userDefaultsWrongAnswerHandlingMode.integerValue];
}

-(void)showHelp
{
    //todo
    //[FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_TRAINING_QUESTIONS", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
}

#pragma mark - Target / Action

- (IBAction)trainCompleteCollectionButtonPressed:(id)sender {
    self.training.exercises = [NSMutableArray arrayWithArray:self.training.collection.exercises.array];
    [self startTraining:[NSNumber numberWithInt:0]];
}

- (IBAction)trainTenWordsButtonPressed:(id)sender {
    
    //create exercises (if necessary)
    if (self.training.collection.exercises.count > 10) {
        [self createExercises:10];
    }
    
    //start training
    [self startTraining:[NSNumber numberWithInt:1]];
}

- (IBAction)trainTwentyFiveWordsButtonPressed:(id)sender {

    //create exercises (if necessary)
    if (self.training.collection.exercises.count > 25) {
        [self createExercises:25];
    }
    
    //start training
    [self startTraining:[NSNumber numberWithInt:2]];
}

- (IBAction)trainFiftyWordsButtonPressed:(id)sender {

    //create exercises (if necessary)
    if (self.training.collection.exercises.count > 50) {
        [self createExercises:50];
    }
    
    //start training
    [self startTraining:[NSNumber numberWithInt:3]];
}

- (IBAction)trainRandomNumberOfWordsButtonPressed:(id)sender {
    int randomCount = arc4random_uniform(self.training.collection.exercises.count - 1);
    
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
    NSNumber *exerciseCount = [NSNumber numberWithUnsignedInteger:self.training.collection.exercises.count];
    for (Exercise *exercise in self.training.collection.exercises) {
        sumOfSuccessRates = [NSNumber numberWithFloat:(sumOfSuccessRates.floatValue + exercise.successRate.floatValue)];
    }
    NSNumber *average = [NSNumber numberWithFloat:(sumOfSuccessRates.floatValue / exerciseCount.floatValue)];
    
    self.training.exercises = [NSMutableArray array];
    if (average.floatValue < 1.0) {
        //if average is lower than 1.0, exercise all words with successrate <= 1.0
        for (Exercise *exercise in self.training.collection.exercises) {
            if (exercise.successRate.floatValue <= 1.0) {
                [self.training.exercises addObject:exercise];
            }
        }
    } else {
        //if average is higher than or equal to 1.0, exercise all words with successrate <= the average
        for (Exercise *exercise in self.training.collection.exercises) {
            if (exercise.successRate.floatValue <= average.floatValue) {
                [self.training.exercises addObject:exercise];
            }
        }
    }
    
    [self startTraining:[NSNumber numberWithInt:5]];
    
}

- (IBAction)trainingModeChanged:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *trainingModeKey = DVT_NSUSERDEFAULTS_TRAININGMODE;
    
    [defaults setObject:[NSNumber numberWithInt:self.modeSelectionControl.selectedSegmentIndex] forKey:trainingModeKey];
    
    [defaults synchronize];
}

- (IBAction)wrongAnswerHandlingModeChanged:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *trainingModeKey = DVT_NSUSERDEFAULTS_WRONGANSWERHANDLINGMODE;
    
    [defaults setObject:[NSNumber numberWithInt:self.wrongAnswerHandlingControl.selectedSegmentIndex] forKey:trainingModeKey];
    
    [defaults synchronize];
}



#pragma mark - Navigation Controller Delegate

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Training"]) {
        //set training 
        [segue.destinationViewController setTraining:self.training];
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
    [self loadPreviousTrainingMode];
    [self loadPreviousWrongAnswerHandlingMode];
    [self.modeSelectionControl addTarget:self action:@selector(trainingModeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.wrongAnswerHandlingControl addTarget:self action:@selector(wrongAnswerHandlingModeChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewDidUnload
{
    [self setModeSelectionControl:nil];
    [self setAllButton:nil];
    [self setRandomButton:nil];
    [self setDifficultButton:nil];
    [self setWrongAnswerHandlingControl:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
@end
