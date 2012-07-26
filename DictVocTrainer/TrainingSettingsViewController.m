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
    
    if (self.collection.exercises.count > 10) {
        //create ten array indexes
        int ints[10];
        for (int i=0; i<10; i++) {
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
        self.exercises = [NSMutableArray arrayWithCapacity:10];
        for (int i=0; i<10; i++) {
            [self.exercises addObject:[self.collection.exercises objectAtIndex:ints[i]]];
        }
        
        //set training title
        self.trainingTitle = self.collection.name;
    }
    
    //start training
    [self performSegueWithIdentifier:@"Show Training" sender:[NSNumber numberWithInt:1]];
}

- (IBAction)trainTwentyFiveWordsButtonPressed:(id)sender {
    if (self.collection.exercises.count > 25) {
        //create twenty array indexes
        int ints[25];
        for (int i=0; i<25; i++) {
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
        self.exercises = [NSMutableArray arrayWithCapacity:25];
        for (int i=0; i<25; i++) {
            [self.exercises addObject:[self.collection.exercises objectAtIndex:ints[i]]];
        }
        
        //set training title
        self.trainingTitle = self.collection.name;
    }
    
    //start training
    [self performSegueWithIdentifier:@"Show Training" sender:[NSNumber numberWithInt:2]];
}

- (IBAction)trainFiftyWordsButtonPressed:(id)sender {
    if (self.collection.exercises.count > 50) {
        //create twenty array indexes
        int ints[50];
        for (int i=0; i<50; i++) {
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
        self.exercises = [NSMutableArray arrayWithCapacity:50];
        for (int i=0; i<50; i++) {
            [self.exercises addObject:[self.collection.exercises objectAtIndex:ints[i]]];
        }
        
        //set training title
        self.trainingTitle = self.collection.name;
    }
    
    //start training
    [self performSegueWithIdentifier:@"Show Training" sender:[NSNumber numberWithInt:3]];
}

- (IBAction)trainRandomNumberOfWordsButtonPressed:(id)sender {
    //todo
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
