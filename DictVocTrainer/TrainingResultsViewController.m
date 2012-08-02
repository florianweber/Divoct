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

#define BAR_WIDTH 90

@interface TrainingResultsViewController ()

@property (weak, nonatomic) IBOutlet TrainingResultsDiagramView *diagramView;
@property (weak, nonatomic) IBOutlet UILabel *redBarLabel;
@property (weak, nonatomic) IBOutlet UIView *redBarView;
@property (weak, nonatomic) IBOutlet UILabel *greenBarLabel;
@property (weak, nonatomic) IBOutlet UIView *greenBarView;
@property (weak, nonatomic) IBOutlet UILabel *wrongCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *correctCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) BOOL finishedDisplayingResults;

@end

@implementation TrainingResultsViewController
@synthesize diagramView;
@synthesize redBarLabel;
@synthesize redBarView;
@synthesize greenBarLabel;
@synthesize greenBarView;
@synthesize wrongCountLabel;
@synthesize correctCountLabel;
@synthesize titleLabel;
@synthesize trainingResult = _trainingResult;
@synthesize finishedDisplayingResults = _finishedDisplayingResults;
@synthesize exercises = _exercises;
@synthesize trainingTitle = _trainingTitle;
@synthesize trainingMode = _trainingMode;

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
    int redBarMidX = self.redBarLabel.center.x;
    int greenBarMidX = self.greenBarLabel.center.x;
    
    self.redBarView.center = CGPointMake(redBarMidX, self.redBarView.center.y);
    self.greenBarView.center = CGPointMake(greenBarMidX, self.greenBarView.center.y);
}

-(void)growBars
{
    int countCorrectInt = [self.trainingResult.countCorrect intValue];
    int countWrongInt = [self.trainingResult.countWrong intValue];
    
    correctCountLabel.text = [NSString stringWithFormat:@"%i",countCorrectInt];
    wrongCountLabel.text = [NSString stringWithFormat:@"%i",countWrongInt];
    
    //calculate bar max height and step increase in points (pixel on normal screen)
    int maxHeight = self.redBarView.frame.origin.y - (titleLabel.center.y + (titleLabel.frame.size.height / 2)) - 15;
    int pixelStepIncrease = maxHeight / (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? 10 : 20);
    
    //bars
    if ((MAX(countCorrectInt, countWrongInt) * pixelStepIncrease) > maxHeight) {
        pixelStepIncrease = (maxHeight / MAX(countCorrectInt, countWrongInt));
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
    
    [UIView animateWithDuration:1 animations:^{
        redBarView.frame = redBarViewFrame; 
        greenBarView.frame = greenBarViewFrame;
    } completion:^(BOOL finished) {
        [self positionCountLabels];
        correctCountLabel.hidden = NO;
        wrongCountLabel.hidden = NO;
    }];
}

-(void)positionCountLabels
{
    self.correctCountLabel.center = CGPointMake(self.greenBarLabel.center.x, self.greenBarView.frame.origin.y - 5 - (self.correctCountLabel.frame.size.height / 2));
    self.wrongCountLabel.center = CGPointMake(self.redBarLabel.center.x, self.redBarView.frame.origin.y - 5 - (self.wrongCountLabel.frame.size.height / 2));
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
    trainingVC.trainingMode = self.trainingMode;
    
    if (self.exercises) {
        trainingVC.exercisesInput = self.exercises;
        trainingVC.trainingTitle = self.trainingTitle;
    } else {
        trainingVC.collection = self.trainingResult.collection;
    }
    
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
    
    [self setupBarViews];
    
    if (!self.finishedDisplayingResults) {
        if (self.exercises) {
            self.titleLabel.text = [self.trainingTitle stringByAppendingFormat:@" - %@", NSLocalizedString(@"TRAINING", nil)];
        } else {
            if ([self.trainingResult.collection.name isEqualToString:NSLocalizedString(@"RECENTS_TITLE", nil)]) {
                self.titleLabel.text = [NSLocalizedString(@"RECENTS_DISPLAY_TITLE", nil) stringByAppendingFormat:@" - %@", NSLocalizedString(@"TRAINING", nil)];
            } else {
                self.titleLabel.text = [self.trainingResult.collection.name stringByAppendingFormat:@" - %@", NSLocalizedString(@"TRAINING", nil)];
            }
        }
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
    [self setRedBarLabel:nil];
    [self setGreenBarLabel:nil];
    [super viewDidUnload];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setupBarViews];
    [self positionCountLabels];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);;
}


@end
