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
#include <stdlib.h>

@interface TrainingSettingsViewController ()

@property (nonatomic, strong) NSMutableArray *exercises;
@property (nonatomic, strong) NSString *trainingTitle;
@property (weak, nonatomic) IBOutlet UIButton *tenButton;
@property (weak, nonatomic) IBOutlet UIButton *twentyFiveButton;
@property (weak, nonatomic) IBOutlet UIButton *fiftyButton;

@end

@implementation TrainingSettingsViewController

@synthesize collection = _collection;
@synthesize exercises = _exercises;
@synthesize trainingTitle = _trainingTitle;
@synthesize tenButton = _TenButton;
@synthesize twentyFiveButton = _TwentyFiveButton;
@synthesize fiftyButton = _FiftyButton;


#pragma mark - Init


#pragma mark - Getter / Setter


#pragma mark - My messages

- (void)configureButtons
{
    //Ten Button
    if (self.collection.exercises.count < 10) {
        self.tenButton.enabled = NO;
        [self grayOutButton:self.tenButton];
        
        self.twentyFiveButton.enabled = NO;
        [self grayOutButton:self.twentyFiveButton];
        
        self.fiftyButton.enabled = NO;
        [self grayOutButton:self.fiftyButton];
        
    } else if ((self.collection.exercises.count >= 10) && (self.collection.exercises.count < 25)) {
        self.twentyFiveButton.enabled = NO;
        [self grayOutButton:self.twentyFiveButton];
        
        self.fiftyButton.enabled = NO;
        [self grayOutButton:self.fiftyButton];
        
    } else if ((self.collection.exercises.count >= 25) && (self.collection.exercises.count < 50)) {
        self.fiftyButton.enabled = NO;
        [self grayOutButton:self.fiftyButton];
        
    } else {
        self.tenButton.enabled = YES;
        self.twentyFiveButton.enabled = YES;
        self.fiftyButton.enabled = YES;
    }
}

-(void)grayOutButton:(UIButton *)button
{
    [button.layer setMasksToBounds:YES];
    button.layer.cornerRadius = 6;
    button.layer.borderColor=[UIColor grayColor].CGColor;//[UIColor colorWithRed:223/255.0 green:223/255.0 blue:223/255.0 alpha:1].CGColor;
    button.layer.borderWidth=1.0f;
    [button setBackgroundImage:[UIImage imageNamed:@"graycolor.png"] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
}

-(void)createExercises:(int)count
{
    //create ten array indexes
    int ints[count];
    for (int i=0; i<count; i++) {
        int randomInt;
        
        bool taken = true;
        while (taken) {
            randomInt = arc4random_uniform(self.collection.exercises.count-1);
            taken = false;
            for (int j=0; j<i; j++) {
                if (randomInt == ints[j]) {
                    taken = true;
                }
            }
        }
        
        ints[i] = randomInt;
    }
    
    //copy these indexes to exercises
    self.exercises = [NSMutableArray arrayWithCapacity:count];
    for (int i=0; i<count; i++) {
        [self.exercises addObject:[self.collection.exercises objectAtIndex:ints[i]]];
    }
    
    //set training title
    self.trainingTitle = self.collection.name;
}

-(void)showHelp
{
    //todo
    //[FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_TRAINING_QUESTIONS", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
}

#pragma mark - Target / Action

- (IBAction)trainCompleteCollectionButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"Show Training" sender:[NSNumber numberWithInt:0]];
}

- (IBAction)trainTenWordsButtonPressed:(id)sender {
    
    //create exercises (if necessary)
    if (self.collection.exercises.count > 10) {
        [self createExercises:10];
    }
    
    //start training
    [self performSegueWithIdentifier:@"Show Training" sender:[NSNumber numberWithInt:1]];
}

- (IBAction)trainTwentyFiveWordsButtonPressed:(id)sender {

    //create exercises (if necessary)
    if (self.collection.exercises.count > 25) {
        [self createExercises:25];
    }
    
    //start training
    [self performSegueWithIdentifier:@"Show Training" sender:[NSNumber numberWithInt:2]];
}

- (IBAction)trainFiftyWordsButtonPressed:(id)sender {

    //create exercises (if necessary)
    if (self.collection.exercises.count > 50) {
        [self createExercises:50];
    }
    
    //start training
    [self performSegueWithIdentifier:@"Show Training" sender:[NSNumber numberWithInt:3]];
}

- (IBAction)trainRandomNumberOfWordsButtonPressed:(id)sender {
    int randomCount = arc4random_uniform(self.collection.exercises.count - 1);
    
    if (randomCount <= 0) {
        randomCount = 1;
    }
    
    //create exercises (if necessary)
    [self createExercises:randomCount];
    
    //start training
    [self performSegueWithIdentifier:@"Show Training" sender:[NSNumber numberWithInt:4]];
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
    
    [self performSegueWithIdentifier:@"Show Training" sender:[NSNumber numberWithInt:5]];
    
}



#pragma mark - Search Bar delegate


#pragma mark - Navigation Controller Delegate

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Training"]) {
        if (((NSNumber *)sender).intValue == 0) {
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
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
@end
