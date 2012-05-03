/*
TrainingResultsViewController.m
 DictVocTrainer
 
 Copyright (C) 2012  Florian Weber
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */


#import <QuartzCore/QuartzCore.h>
#import "TrainingResultsViewController.h"
#import "TrainingResultsDiagramView.h"
#import "TrainingViewController.h"
#import "FWToastView.h"

#define MAX_BAR_HEIGHT 237
#define NORMAL_PIXEL_STEPS 10

@interface TrainingResultsViewController ()

@property (weak, nonatomic) IBOutlet TrainingResultsDiagramView *diagramView;
@property (weak, nonatomic) IBOutlet UIView *redBarView;
@property (weak, nonatomic) IBOutlet UIView *greenBarView;
@property (weak, nonatomic) IBOutlet UILabel *wrongCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *correctCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) BOOL finishedDisplayingResults;

@end

@implementation TrainingResultsViewController
@synthesize diagramView;
@synthesize redBarView;
@synthesize greenBarView;
@synthesize wrongCountLabel;
@synthesize correctCountLabel;
@synthesize titleLabel;
@synthesize trainingResult = _trainingResult;
@synthesize finishedDisplayingResults = _finishedDisplayingResults;

#pragma mark - Init


#pragma mark - Getter / Setter

-(void)setTrainingResult:(TrainingResult *)trainingResult
{
    if(trainingResult != _trainingResult) {
        _trainingResult = trainingResult;
        
    }
}


#pragma mark - My messages

-(void)setupBarViews
{
    //red bar
    CGRect redBarViewFrame = self.redBarView.frame;
    redBarViewFrame.size.height = NORMAL_PIXEL_STEPS;
    self.redBarView.frame = redBarViewFrame;
    
    //green bar
    CGRect greenBarViewFrame = self.greenBarView.frame;
    greenBarViewFrame.size.height = NORMAL_PIXEL_STEPS;
    self.greenBarView.frame = greenBarViewFrame;
    
}

-(void)growBars
{
    int countCorrectInt = [self.trainingResult.countCorrect intValue];
    int countWrongInt = [self.trainingResult.countWrong intValue];
    
    correctCountLabel.text = [NSString stringWithFormat:@"%i",countCorrectInt];
    wrongCountLabel.text = [NSString stringWithFormat:@"%i",countWrongInt];
    
    //bars
    int pixelStepIncrease = NORMAL_PIXEL_STEPS;
    
    if ((MAX(countCorrectInt, countWrongInt) * NORMAL_PIXEL_STEPS) > MAX_BAR_HEIGHT) {
        pixelStepIncrease = (MAX_BAR_HEIGHT / MAX(countCorrectInt, countWrongInt)); 
    }
    
    int wrongBarHeight = self.redBarView.frame.size.height + (countWrongInt * pixelStepIncrease);
    int correctBarHeight = self.greenBarView.frame.size.height + (countCorrectInt * pixelStepIncrease);
    
    
    CGRect redBarViewFrame = self.redBarView.frame;
    if (wrongBarHeight > self.redBarView.frame.size.height) {
        redBarViewFrame.size.height = wrongBarHeight;
        redBarViewFrame.origin.y = redBarViewFrame.origin.y - wrongBarHeight + self.redBarView.frame.size.height;
    }
    
    CGRect greenBarViewFrame = self.greenBarView.frame;
    if (correctBarHeight > self.greenBarView.frame.size.height) {
        greenBarViewFrame.size.height = correctBarHeight;
        greenBarViewFrame.origin.y = greenBarViewFrame.origin.y - correctBarHeight + self.greenBarView.frame.size.height;
    }
    
    //count labels
    CGRect correctCountLabelFrame = self.correctCountLabel.frame;
    correctCountLabelFrame.origin.y = greenBarViewFrame.origin.y - 5 - correctCountLabelFrame.size.height;
    
    CGRect wrongCountLabelFrame = self.wrongCountLabel.frame;
    wrongCountLabelFrame.origin.y = redBarViewFrame.origin.y - 5 - wrongCountLabelFrame.size.height;
    
    [UIView animateWithDuration:1 animations:^{
        redBarView.frame = redBarViewFrame; 
        greenBarView.frame = greenBarViewFrame;
    } completion:^(BOOL finished) {
        self.correctCountLabel.frame = correctCountLabelFrame;
        self.wrongCountLabel.frame = wrongCountLabelFrame;
        correctCountLabel.hidden = NO;
        wrongCountLabel.hidden = NO;
    }];
}

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        [self retryButtonPressed:nil];
    } else if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        [[self navigationController] popViewControllerAnimated:YES];
    }
}

-(void)addSwipeGestureRecognizer
{
    UISwipeGestureRecognizer *rightSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                                      action:@selector(handleSwipeFrom:)];
    rightSwiper.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwiper];
    
    UISwipeGestureRecognizer *leftSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                                     action:@selector(handleSwipeFrom:)];
    leftSwiper.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:leftSwiper];
}

-(void)showHelp 
{
    [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_TRAINING_RESULTS", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
}

#pragma mark - Target / Action
- (IBAction)retryButtonPressed:(UIBarButtonItem *)sender {
    TrainingViewController *trainingVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Training"];
    trainingVC.collection = self.trainingResult.collection;
    
    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:[[self navigationController] viewControllers]];
    [viewControllers removeLastObject];
    [viewControllers addObject:trainingVC];
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.5; 
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]; 
    transition.type = kCATransitionFade;
    transition.delegate = self;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    
    [[self navigationController] setViewControllers:viewControllers animated:NO];
}

-(IBAction)displayResults:(id)sender
{
    [self growBars];
    self.finishedDisplayingResults = YES;
}

#pragma mark - Search Bar delegate


#pragma mark - Navigation Controller Delegate


#pragma mark - View lifecycle


-(void)viewDidLoad
{
    [super viewDidLoad];
    [self addSwipeGestureRecognizer];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.finishedDisplayingResults) {
        self.titleLabel.text = [self.trainingResult.collection.name stringByAppendingFormat:@" - %@", NSLocalizedString(@"TRAINING", nil)];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.finishedDisplayingResults) {
        [self performSelector:@selector(displayResults:) withObject:nil afterDelay:0.5];
    }
}

- (void)viewDidUnload
{
    [self setDiagramView:nil];
    [self setRedBarView:nil];
    [self setGreenBarView:nil];
    [self setWrongCountLabel:nil];
    [self setCorrectCountLabel:nil];
    [self setTitleLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
