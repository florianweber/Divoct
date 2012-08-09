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
#import "PickerViewController.h"
#import "Logging.h"
#include <stdlib.h>

@interface TrainingSettingsViewController () <PickerViewControllerDelegate>

@property (weak, nonatomic) IBOutlet MOGlassButton *tenButton;
@property (weak, nonatomic) IBOutlet MOGlassButton *twentyFiveButton;
@property (weak, nonatomic) IBOutlet MOGlassButton *fiftyButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *modeSelectionControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *wrongAnswerHandlingControl;
@property (weak, nonatomic) IBOutlet MOGlassButton *allButton;
@property (weak, nonatomic) IBOutlet MOGlassButton *randomButton;
@property (weak, nonatomic) IBOutlet MOGlassButton *difficultButton;
@property (nonatomic, strong) Training *training;
@property (weak, nonatomic) IBOutlet UIButton *wordCountButton;
@property (nonatomic, strong) NSArray *pickList;

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
@synthesize wordCountButton = _wordCountButton;

NSString *const DVT_TRAINING_WORDCOUNT_KEY_ALL = @"All";
NSString *const DVT_TRAINING_WORDCOUNT_KEY_RANDOM = @"Random";
NSString *const DVT_TRAINING_WORDCOUNT_KEY_DIFFICULT = @"Difficult";

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

-(void)startTraining
{
    //Create Exercises
    NSString *requestedWordCount = self.wordCountButton.titleLabel.text;
    
    NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *numberOfWords = [numberFormatter numberFromString:requestedWordCount];
    
    if (numberOfWords) {
        [self createExercises:numberOfWords.intValue];
    } else {
        //All
        if (requestedWordCount == DVT_TRAINING_WORDCOUNT_KEY_ALL) {
            self.training.exercises = [NSMutableArray arrayWithArray:self.training.collection.exercises.array];
        //Random
        } else if (requestedWordCount == DVT_TRAINING_WORDCOUNT_KEY_RANDOM) {
            int randomCount = arc4random_uniform(self.training.collection.exercises.count - 1);
            
            if (randomCount <= 0) {
                randomCount = 1;
            }
            [self createExercises:randomCount];
        //Difficult
        } else if (requestedWordCount == DVT_TRAINING_WORDCOUNT_KEY_DIFFICULT) {
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
        } else {
            //error
            LogError(@"Nome weired number of required words appeared");
        }
    }
    
    
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

-(NSArray *)pickerItemsForWordCount
{
    NSMutableArray *wordCountPickerItems = [[NSMutableArray alloc] init];
    [wordCountPickerItems addObject:DVT_TRAINING_WORDCOUNT_KEY_ALL];
    [wordCountPickerItems addObject:DVT_TRAINING_WORDCOUNT_KEY_RANDOM];
    [wordCountPickerItems addObject:DVT_TRAINING_WORDCOUNT_KEY_DIFFICULT];
    
    for (int i=10; i<=self.training.collection.exercises.count; i+=10) {
        [wordCountPickerItems addObject:[NSString stringWithFormat:@"%d", i]];
    }
    
    return wordCountPickerItems;
}

-(void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
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
    [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_TRAININGSETTINGS", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
}

#pragma mark - Target / Action

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

- (IBAction)chooseWordCountButtonPressed:(id)sender {
    
    [self performSegueWithIdentifier:@"Show Picker" sender:sender];
}

- (IBAction)goButtonPressed:(id)sender {
    [self startTraining];
}

#pragma mark - Picker View Controller Delegate

-(void)pickerViewController:(PickerViewController *)pickerViewController pickedValue:(NSString *)value
{
    if (value != nil) {
        [self.wordCountButton setTitle:value forState:UIControlStateNormal];
    }
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Navigation Controller Delegate

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Training"]) {
        //set training
        [segue.destinationViewController setTraining:self.training];
    } else if ([segue.identifier isEqualToString:@"Show Picker"]) {
        [segue.destinationViewController setDelegate:self];
        
        NSArray *pickerItems = [self pickerItemsForWordCount];
        [segue.destinationViewController setPickList:pickerItems];
        
        int preselectedIndex=0;
        for (NSString *item in pickerItems) {
            if ([self.wordCountButton.titleLabel.text isEqualToString:item]) {
                break;
            }
            preselectedIndex++;
        }
        
        [segue.destinationViewController setPreselectedRow:preselectedIndex];
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
    [self addSwipeGestureRecognizer];
}

- (void)viewDidUnload
{
    [self setModeSelectionControl:nil];
    [self setAllButton:nil];
    [self setRandomButton:nil];
    [self setDifficultButton:nil];
    [self setWrongAnswerHandlingControl:nil];
    [self setWordCountButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
@end
