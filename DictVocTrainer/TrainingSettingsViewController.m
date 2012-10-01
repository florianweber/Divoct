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

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *modeSelectionControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *wrongAnswerHandlingControl;
@property (nonatomic, strong) Training *training;
@property (weak, nonatomic) IBOutlet MOGlassButton *wordCountButton;
@property (weak, nonatomic) IBOutlet MOGlassButton *startTrainingButton;
@property (nonatomic, strong) NSArray *pickList;

@end

@implementation TrainingSettingsViewController

@synthesize modeSelectionControl = _modeSelectionControl;
@synthesize wrongAnswerHandlingControl = _wrongAnswerHandlingControl;
@synthesize training = _training;
@synthesize wordCountButton = _wordCountButton;
@synthesize startTrainingButton = _startTrainingButton;


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
    [self.wordCountButton setupAsDarkGrayButton];
    [self.wordCountButton setTitle:NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_ALL", nil) forState:UIControlStateNormal];
    
    [self.startTrainingButton setupAsFocusIndicatorBlueButton];
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
        if ([requestedWordCount isEqualToString:NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_ALL", nil)]) {
            self.training.exercises = [NSMutableArray arrayWithArray:self.training.collection.exercises.array];
        //Random
        } else if ([requestedWordCount isEqualToString:NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_RAND", nil)]) {
            int randomCount = arc4random_uniform(self.training.collection.exercises.count - 1);
            
            if (randomCount <= 0) {
                randomCount = 1;
            }
            [self createExercises:randomCount];
        //Difficult
        } else if ([requestedWordCount isEqualToString:NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_DIFF", nil)]) {
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
    [wordCountPickerItems addObject:NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_ALL", nil)];
    [wordCountPickerItems addObject:NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_RAND", nil)];
    [wordCountPickerItems addObject:NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_DIFF", nil)];
    
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
    
    [self performSegueWithIdentifier:@"Show WordCount Picker" sender:sender];
}

- (IBAction)startTrainingButtonPressed:(id)sender {
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
    } else if ([segue.identifier isEqualToString:@"Show WordCount Picker"]) {
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
        
        [segue.destinationViewController setDescription:NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_DESC", nil)];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureButtons];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadPreviousTrainingMode];
    [self loadPreviousWrongAnswerHandlingMode];
    [self.modeSelectionControl addTarget:self action:@selector(trainingModeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.wrongAnswerHandlingControl addTarget:self action:@selector(wrongAnswerHandlingModeChanged:) forControlEvents:UIControlEventValueChanged];
    [self addSwipeGestureRecognizer];
    
    self.scrollView.contentSize = CGSizeMake(320, 367);
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        [self.scrollView flashScrollIndicators];
    }
}

- (void)viewDidUnload
{
    [self setModeSelectionControl:nil];
    [self setWrongAnswerHandlingControl:nil];
    [self setWordCountButton:nil];
    [self setStartTrainingButton:nil];
    [self setScrollView:nil];
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
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        [self.scrollView flashScrollIndicators];
    }
}
@end
