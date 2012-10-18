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
#import "CollectionPickerViewController.h"
#import "DictVocSettings.h"
#include <stdlib.h>

@interface TrainingSettingsViewController () <PickerViewControllerDelegate, CollectionPickerViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *modeSelectionControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *wrongAnswerHandlingControl;
@property (nonatomic, strong) Training *training;
@property (weak, nonatomic) IBOutlet MOGlassButton *collectionChooserButton;
@property (weak, nonatomic) IBOutlet MOGlassButton *wordCountButton;
@property (nonatomic, strong) NSArray *pickList;

@end

@implementation TrainingSettingsViewController

@synthesize modeSelectionControl = _modeSelectionControl;
@synthesize wrongAnswerHandlingControl = _wrongAnswerHandlingControl;
@synthesize training = _training;
@synthesize collectionChooserButton = _collectionChooserButton;
@synthesize wordCountButton = _wordCountButton;


#pragma mark - Getter / Setter

-(void)setCollection:(Collection *)collection
{
    if(collection) {
        self.training = [[Training alloc] init];
        self.training.collections = [[NSSet alloc] initWithObjects:collection, nil];
        [self refreshCollectionChooserButtonTitle];
    }
}

-(void)setCollections:(NSMutableSet *)collections
{
    if (collections) {
        if (!self.training) {
            self.training = [[Training alloc] init];
        }
        self.training.collections = collections;
        [self refreshCollectionChooserButtonTitle];
    }
}


#pragma mark - My messages

- (void)configureButtons
{
    [self.collectionChooserButton setupAsDarkGrayButton];
    [self refreshCollectionChooserButtonTitle];
    [self.wordCountButton setupAsDarkGrayButton];
    [self.wordCountButton setTitle:NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_ALL", nil) forState:UIControlStateNormal];
}

- (void)refreshCollectionChooserButtonTitle
{
    if (self.training.collections && (self.training.collections.count > 0)) {
        [self.collectionChooserButton setTitle:self.training.title forState:UIControlStateNormal];
    } else {
        [self.collectionChooserButton setTitle:NSLocalizedString(@"TRAINING_SETTINGS_COLLECTIONPICKER_EMPTY", nil) forState:UIControlStateNormal];
    }
}

-(void)createExercises:(int)count
{
    //create self.exercises
    self.training.exercises = [NSMutableSet setWithCapacity:count];
    
    //copy all available exercises and reduce this new array by the amount of count
    NSMutableSet *availableExercises = [NSMutableSet set];
    for (Collection *collection in self.training.collections) {
        [availableExercises addObjectsFromArray:collection.exercises.array];
    }
    
    NSMutableArray *availableExercisesArray = [[NSMutableArray alloc] initWithArray:availableExercises.allObjects];
    
    int randomIndex;
    int upperBoundIndex;
    while (count > 0) {
        upperBoundIndex = [availableExercisesArray count] - 1;
        randomIndex = arc4random_uniform(upperBoundIndex);
        [self.training.exercises addObject:[availableExercisesArray objectAtIndex:randomIndex]];
        [availableExercisesArray removeObjectAtIndex:randomIndex];
        count--;
    }
}

-(void)startTraining
{
    if (self.training.collections.count == 0) {
        //no collection has been selected yet
        [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_TRAININGSETTINGS_NOVOC", nil) icon:FWToastViewIconAlert duration:FWToastViewDurationUnlimited withCloseButton:YES];
        
    } else {
        //Warning for Difficult words, if there are no difficult words anymore
        BOOL showWarning = NO;
    
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
                self.training.exercises = [NSMutableSet set];
                for (Collection *collection in self.training.collections) {
                    [self.training.exercises addObjectsFromArray:collection.exercises.array];
                }
            //Random
            } else if ([requestedWordCount isEqualToString:NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_RAND", nil)]) {
                int randomCount = arc4random_uniform([self.training totalExerciseCountAvailableWithoutDuplicates] - 1);
                
                if (randomCount <= 0) {
                    randomCount = 1;
                }
                [self createExercises:randomCount];
            //Difficult
            } else if ([requestedWordCount isEqualToString:NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_DIFF", nil)]) {
                //all exercises
                NSMutableSet *allExercises = [NSMutableSet set];
                for (Collection *collection in self.training.collections) {
                    [allExercises addObjectsFromArray:collection.exercises.array];
                }
                
                //calculate statistics
                NSNumber *sumOfSuccessRates = [NSNumber numberWithFloat:0.0];
                NSNumber *exerciseCount = [NSNumber numberWithUnsignedInteger:[self.training totalExerciseCountAvailableWithoutDuplicates]];
                for (Exercise *exercise in allExercises) {
                    sumOfSuccessRates = [NSNumber numberWithFloat:(sumOfSuccessRates.floatValue + exercise.successRate.floatValue)];
                }
                NSNumber *average = [NSNumber numberWithFloat:(sumOfSuccessRates.floatValue / exerciseCount.floatValue)];
                
                //warn for well known words
                if (average.intValue == 2) {
                    showWarning = [DictVocSettings instance].trainingWarnWellKnownOnly;
                }
                
                self.training.exercises = [NSMutableSet set];
                for (Exercise *exercise in allExercises) {
                    //exercise all words where the successrate is lower than average
                    if (exercise.successRate.floatValue <= average.floatValue) {
                        [self.training.exercises addObject:exercise];
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

        if (showWarning) {
            [self showAlert];
        } else if (self.training.exercises.count == 0) {
            [FWToastView toastInView:self.view withText:NSLocalizedString(@"TRAINING_NO_WORDS_WARNING", nil) icon:FWToastViewIconWarning duration:FWToastViewDurationUnlimited withCloseButton:YES];
        } else {
            [self performSegueWithIdentifier:@"Show Training" sender:self];
        }
        
    }
}

-(void)showAlert
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"TRAINING_ALL_WORDS_WELLKNOWN_WARN_TITLE", nil)
                                                      message:NSLocalizedString(@"TRAINING_ALL_WORDS_WELLKNOWN_WARN_MESSAGE", nil)
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"TRAINING_ALL_WORDS_WELLKNOWN_WARN_NO", nil)
                                            otherButtonTitles:NSLocalizedString(@"TRAINING_ALL_WORDS_WELLKNOWN_WARN_YES", nil),nil];
    
    [message show];
}

-(void)loadSavedSettings
{
    [self loadPreviousTrainingMode];
    
}

-(void)loadPreviousTrainingMode
{
    [self.modeSelectionControl setSelectedSegmentIndex:[DictVocSettings instance].trainingAnswerInputMode];
}

-(void)loadPreviousWrongAnswerHandlingMode
{
    [self.wrongAnswerHandlingControl setSelectedSegmentIndex:[DictVocSettings instance].trainingWrongAnswerHandling];
}

-(NSArray *)pickerItemsForWordCount
{
    NSMutableArray *wordCountPickerItems = [[NSMutableArray alloc] init];
    [wordCountPickerItems addObject:NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_ALL", nil)];
    [wordCountPickerItems addObject:NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_RAND", nil)];
    [wordCountPickerItems addObject:NSLocalizedString(@"TRAINING_SETTINGS_COUNTPICKER_DIFF", nil)];
    
    int totalCountOfAvailableExercises = [self.training totalExerciseCountAvailableWithoutDuplicates];
    for (int i=10; i<=totalCountOfAvailableExercises; i+=10) {
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
    if (self.modeSelectionControl.selectedSegmentIndex == 0) {
        [DictVocSettings instance].trainingAnswerInputMode = TrainingAnswerInputMode_MultipleChoice;
    } else if (self.modeSelectionControl.selectedSegmentIndex == 1) {
        [DictVocSettings instance].trainingAnswerInputMode = TrainingAnswerInputMode_TextInput;
    }
}

- (IBAction)wrongAnswerHandlingModeChanged:(id)sender {
    if (self.wrongAnswerHandlingControl.selectedSegmentIndex == 0) {
        [DictVocSettings instance].trainingWrongAnswerHandling = TrainingWrongAnswerHandlingMode_Repeat;
    } else if (self.wrongAnswerHandlingControl.selectedSegmentIndex == 1) {
        [DictVocSettings instance].trainingWrongAnswerHandling = TrainingWrongAnswerHandlingMode_Dismiss;
    }
}

- (IBAction)chooseWordCountButtonPressed:(id)sender {
    
    [self performSegueWithIdentifier:@"Show WordCount Picker" sender:sender];
}

- (IBAction)chooseCollectionsButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"Show Collection Picker" sender:sender];
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

#pragma mark - Collection Picker View Controller Delegate

-(void)collectionPickerViewController:(CollectionPickerViewController *)collectionPickerViewController pickedCollections:(NSMutableSet *)collections
{
    if (collections != nil) {
        [self setCollections:collections];
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
    } else if ([segue.identifier isEqualToString:@"Show Collection Picker"]) {
        [segue.destinationViewController setDelegate:self];
        [segue.destinationViewController setSelectedCollections:[self.training.collections mutableCopy]];
    }
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
    {
        LogDebug(@"Cancel Button was selected.");
    }
    else if (buttonIndex == 1)
    {
        LogDebug(@"Confirm Button was selected.");
        [self performSegueWithIdentifier:@"Show Training" sender:self];
    }
    else
    {
        LogDebug(@"Unknown Button was selected.");
    }
    
}

#pragma mark - View Lifecycle

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
    [self setScrollView:nil];
    [self setCollectionChooserButton:nil];
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
