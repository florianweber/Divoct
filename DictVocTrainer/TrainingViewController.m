/*
TrainingViewController.m
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
#import "TrainingViewController.h"
#import "TrainingView.h"
#import "TrainingStatusView.h"
#import "QuestionView.h"
#import "Exercise+Extended.h"
#import "SQLiteWord.h"
#import "DictVocDictionary.h"
#import "DictVocTrainer.h"
#import "TrainingResult.h"
#import "TrainingResultsViewController.h"
#import "Translation.h"
#import "FWToastView.h"

@interface TrainingViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *stopButton;

@property (weak, nonatomic) IBOutlet TrainingView *trainingView;
@property (weak, nonatomic) IBOutlet TrainingStatusView *trainingStatusView;
@property (weak, nonatomic) IBOutlet UILabel *completionLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progessView;
@property (weak, nonatomic) IBOutlet UIImageView *questionFlagIconImageView;
@property (weak, nonatomic) IBOutlet UIScrollView *questionScrollView;
@property (weak, nonatomic) IBOutlet QuestionView *questionView;

@property (weak, nonatomic) IBOutlet UIButton *optionOneButton;
@property (weak, nonatomic) IBOutlet UIButton *optionTwoButton;
@property (weak, nonatomic) IBOutlet UIButton *optionThreeButton;
@property (weak, nonatomic) IBOutlet UIButton *optionFourButton;
@property (nonatomic, strong) NSArray *answerButtons;

@property (nonatomic, strong) NSMutableArray *openExercises;
@property (nonatomic, strong) NSNumber *countDone;
@property (nonatomic, strong) NSNumber *countWrong;
@property (nonatomic, strong) NSNumber *countCorrect;
@property (nonatomic, strong) NSNumber *exerciseCount;
@property (nonatomic, strong) NSMutableArray *currentQuestionCorrectAnswerButtons;
@property (nonatomic, strong) Exercise *currentExercise;
@property (nonatomic, strong) SQLiteWord *currentWord;
@property (nonatomic, strong) NSMutableArray *currentTranslations;
@property (nonatomic) BOOL currentExerciseWrong;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic) CGRect questionViewOriginalFrame;


@end

@implementation TrainingViewController
@synthesize stopButton = _stopButton;
@synthesize trainingView;
@synthesize trainingStatusView;
@synthesize completionLabel;
@synthesize progessView;
@synthesize questionFlagIconImageView;
@synthesize questionScrollView;
@synthesize questionView;
@synthesize optionOneButton;
@synthesize optionTwoButton;
@synthesize optionThreeButton;
@synthesize optionFourButton;
@synthesize collection = _collection;
@synthesize openExercises = _openExercises;
@synthesize countDone = _countDone;
@synthesize exerciseCount = _exerciseCount;
@synthesize currentQuestionCorrectAnswerButtons = _currentQuestionCorrectAnswerButtons;
@synthesize answerButtons = _answerButtons;
@synthesize currentExercise = _currentExercise;
@synthesize currentWord = _currentWord;
@synthesize questionViewOriginalFrame = _questionViewOriginalFrame;
@synthesize countCorrect = _countCorrect;
@synthesize countWrong = _countWrong;
@synthesize currentExerciseWrong = _currentExerciseWrong;
@synthesize trainingResultsObjectId = _trainingResultsObjectId;
@synthesize timer = _timer;
@synthesize currentTranslations = _currentTranslations;

#pragma mark - Init


#pragma mark - Getter / Setter

-(void)setCurrentWord:(SQLiteWord *)currentWord
{
    if (currentWord != _currentWord) {
        if (!currentWord.translations || [currentWord.translations count] == 0) {
            if (self.currentExercise.trainingTranslations && [self.currentExercise.trainingTranslations count] > 0) {
                NSMutableArray *translationUniqueIds = [[NSMutableArray alloc] initWithCapacity:[self.currentExercise.trainingTranslations count]];
                for (Translation *translation in self.currentExercise.trainingTranslations) {
                    [translationUniqueIds addObject:translation.uniqueId];
                }
                _currentWord = [[DictVocDictionary instance] getRelationsShipsForWord:currentWord withTranslationIds:translationUniqueIds];
            } else {
                _currentWord = [[DictVocDictionary instance] getRelationsShipsForWord:currentWord];
            }
        } else {
            _currentWord = currentWord;
        }
    }
}

-(void)setCollection:(Collection *)collection
{
    if (collection) {
        _collection = collection;
        self.openExercises = [collection.exercises mutableCopy];
        self.countDone = [NSNumber numberWithInt:0];
        self.exerciseCount = [NSNumber numberWithInt:[self.openExercises count]];
        self.completionLabel.text = [NSString stringWithFormat:@"0 / %i", self.exerciseCount];
        self.title = [collection.name stringByAppendingFormat:@" - %@", NSLocalizedString(@"TRAINING", nil)];
    }
}

-(void)setAnswerButtons:(NSArray *)answerButtons
{
    if (answerButtons != _answerButtons) {
        _answerButtons = answerButtons;
        for (UIButton *button in _answerButtons) {
            [button.layer setMasksToBounds:YES];
            button.layer.cornerRadius = 6;
            button.layer.borderColor=[UIColor grayColor].CGColor;
            button.layer.borderWidth=1.5f;
        }
    }
}

-(NSArray *)answerButtons
{
    if(!_answerButtons) {
        self.answerButtons = [NSArray arrayWithObjects:self.optionOneButton, self.optionTwoButton, self.optionThreeButton, self.optionFourButton, nil];
    }
    return _answerButtons;
}

-(NSMutableArray *)currentQuestionCorrectAnswerButtons 
{
    if (!_currentQuestionCorrectAnswerButtons) {
        self.currentQuestionCorrectAnswerButtons = [[NSMutableArray alloc] init];
    }
    return _currentQuestionCorrectAnswerButtons;
}


#pragma mark - My messages

- (void)setStopButtonTitle:(NSString *)title
{
    self.stopButton.title = title;
}

-(void)setupProgressBar
{
    self.countWrong = [NSNumber numberWithInt:0];
    self.countCorrect = [NSNumber numberWithInt:0];
    self.progessView.progress = 0.0;
    self.progessView.progressTintColor = [UIColor greenColor];
}

-(void)updateFlagIcon
{
    if (self.currentWord.languageCode.intValue == WordLanguageEnglish) {
        self.questionFlagIconImageView.image = [UIImage imageNamed:@"flagUK.png"];
    } else {
        self.questionFlagIconImageView.image = [UIImage imageNamed:@"flagGermany.png"];
    }
}

-(void)updateQuestion
{
    //remove all subviews in case this viewController instance has been used before
    for (UIView *subview in self.questionView.subviews) {
        [subview removeFromSuperview];
    }
    
    CGSize maxFrameSize = CGSizeMake(self.questionView.frame.size.width - 10, 20000);
    
    //Start point top left
    CGPoint descStart;
    descStart.x = 0;
    descStart.y = 10;
    
    //Title (searched word)
    UILabel *questionLabel = [[UILabel alloc] init];
    questionLabel.text = self.currentWord.name;
    questionLabel.font = [UIFont boldSystemFontOfSize:22];
    questionLabel.textAlignment = UITextAlignmentCenter;
    questionLabel.backgroundColor = [UIColor clearColor];
    questionLabel.numberOfLines = 0;
    questionLabel.lineBreakMode = UILineBreakModeWordWrap;
    
    CGRect questionFrame = questionLabel.frame;
    questionFrame.origin = descStart;
    questionFrame.size = [questionLabel.text sizeWithFont:questionLabel.font constrainedToSize:maxFrameSize lineBreakMode:UILineBreakModeWordWrap];
    questionFrame.size.width = self.questionViewOriginalFrame.size.width;
    
    questionLabel.frame = questionFrame;
    
    [self.questionView addSubview:questionLabel];
    
    //change vocabularyDetailView.frame to fit the subviews' size
    CGFloat contentHeight = descStart.y + questionFrame.size.height + 20;
    if (contentHeight > self.questionScrollView.frame.size.height) {
        CGSize sizeFittingSubviews = CGSizeMake(self.questionView.frame.size.width, contentHeight);
        
        CGRect newFrame = self.questionView.frame;
        newFrame.size = sizeFittingSubviews;
        self.questionView.frame = newFrame;
    } else {
        self.questionView.frame = self.questionViewOriginalFrame;
    }
    self.questionScrollView.contentSize = self.questionView.frame.size;
}

-(void)updateButtons
{
    //clear button colors
    for (UIButton *button in self.answerButtons) {
        [button setBackgroundImage:[UIImage imageNamed:@"whitecolor.png"] forState:UIControlStateNormal];
    }
    
    //reset correct answer buttons
    [self.currentQuestionCorrectAnswerButtons removeAllObjects];
    
    int maxAvailableCorrectAnswers = [self.currentWord.translations count];
    int amountCorrectAnswers = MAX(1, arc4random_uniform(maxAvailableCorrectAnswers % [self.answerButtons count]));
    
    NSMutableArray *mutableAnswerButtons = [self.answerButtons mutableCopy];
    
    int usedAnswerIndexes[3] = {-1, -1, -1};
    int currentUsedAnswerIndex = 0;
    
    //correct answers
    for (int i=0; i<amountCorrectAnswers; i++) {
        //get random button
        int randomButtonIndex = arc4random_uniform([mutableAnswerButtons count]);
        UIButton *answerButton = [mutableAnswerButtons objectAtIndex:randomButtonIndex];
        
        //get random correct answer
        int randomAnswerIndex = arc4random_uniform(maxAvailableCorrectAnswers);
        BOOL indexAlreadyUsed = YES;
        while (indexAlreadyUsed) {
            int j;
            for(j=0; j<3; j++) {
                if (randomAnswerIndex == usedAnswerIndexes[j]) {
                    randomAnswerIndex = (randomAnswerIndex + 1) % (maxAvailableCorrectAnswers-1);
                    indexAlreadyUsed = YES;
                } else {
                    indexAlreadyUsed = NO;
                }
            }
        }
        usedAnswerIndexes[currentUsedAnswerIndex] = randomAnswerIndex;
        currentUsedAnswerIndex++;
        
        //set button
        [answerButton setTitle:((SQLiteWord *)[self.currentWord.translations objectAtIndex:randomAnswerIndex]).name forState:UIControlStateNormal];
        [self.currentQuestionCorrectAnswerButtons addObject:answerButton];
        [mutableAnswerButtons removeObject:answerButton];
    }
    
    NSNumber *translationLanguageCode;
    if ([self.currentWord.languageCode intValue] == WordLanguageEnglish) {
        translationLanguageCode = [NSNumber numberWithInt:WordLanguageGerman];
    } else {
        translationLanguageCode = [NSNumber numberWithInt:WordLanguageEnglish];
    }
    
    //wrong answers
    int buttonCountLeft = [mutableAnswerButtons count];
    while(buttonCountLeft > 0) {
        int randomWrongButtonIndex = arc4random_uniform([mutableAnswerButtons count]);
        UIButton *wrongAnswerButton = [mutableAnswerButtons objectAtIndex:randomWrongButtonIndex];
        [wrongAnswerButton setTitle:[[DictVocDictionary instance] randomWordWithLanguageCode:translationLanguageCode].name forState:UIControlStateNormal];
        [mutableAnswerButtons removeObject:wrongAnswerButton];
        buttonCountLeft = [mutableAnswerButtons count];
    } 
}

-(void)updateProgress
{
    self.completionLabel.text = [NSString stringWithFormat:@"%i / %i", [self.countDone intValue], [self.exerciseCount intValue]];
    
    [self.progessView setProgress:([self.countDone floatValue] / [self.exerciseCount floatValue]) animated:YES];
}

-(void)showResults:(TrainingResult *)trainingResult
{
    TrainingResultsViewController *resultsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Training Results"];
    resultsVC.trainingResult = trainingResult;
    
    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:[[self navigationController] viewControllers]];
    [viewControllers removeLastObject];
    [viewControllers addObject:resultsVC];
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.5; 
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]; 
    transition.type = kCATransitionFade;
    //transition.subtype = kCATransitionFromLeft;
    transition.delegate = self;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    
    [[self navigationController] setViewControllers:viewControllers animated:NO];
    
}

-(void)completeTraining
{
    for (UIButton *button in self.answerButtons) {
        button.enabled = NO;
    }
    
    TrainingResult *trainingResult = nil;
    if (self.trainingResultsObjectId) {
        trainingResult = [[DictVocTrainer instance] trainingResultWithObjectId:self.trainingResultsObjectId];
    }
    
    if (!trainingResult) {
        trainingResult = [[DictVocTrainer instance] insertTrainingResultWithCountWrong:self.countWrong countCorrect:self.countCorrect countWords:self.exerciseCount collection:self.collection trainingDate:[NSDate date]];
    }
    [self showResults:trainingResult];
}

-(void)showHelp 
{
    [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_TRAINING_QUESTIONS", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES pointingToView:optionOneButton fromDirection:FWToastViewPointingFromDirectionTop];
}


#pragma mark - Target / Action

- (IBAction)cancelButtonPressed:(id)sender {
    [self completeTraining];
}


-(IBAction)nextExercise:(id)sender
{
    self.currentExerciseWrong = NO;
    
    //complete training if this was the last exercise, otherwise continue
    if ([self.openExercises count] == 0) {
        [self completeTraining];
    } else {
        self.currentExercise = [self.openExercises objectAtIndex:arc4random_uniform([self.openExercises count])];
        self.currentWord = self.currentExercise.word;
        [self updateFlagIcon];
        [self updateQuestion];
        [self updateButtons];
    }
}

-(IBAction)optionButtonPressed:(UIButton *)sender 
{
    if (![self.timer isValid]) {
        //answer correct
        if ([self.currentQuestionCorrectAnswerButtons containsObject:sender]) {
            if (!self.currentExerciseWrong) {
                self.countCorrect = [NSNumber numberWithInt:([self.countCorrect intValue] + 1)];
            }
            
            self.countDone = [NSNumber numberWithInt:([self.countDone intValue] + 1)];
            
            //paint button green to show the answer was correct
            [sender setBackgroundImage:[UIImage imageNamed:@"greencolor.png"] forState:UIControlStateNormal];
            
            //remove solved exercise from open list
            [self.openExercises removeObject:self.currentExercise];
            
            //update progress
            [self updateProgress];
            
            //go to next exercise after 1 second
            self.timer = [NSTimer scheduledTimerWithTimeInterval:DVT_WAITSECONDS_FOR_TRAINING_NEXT 
                                                                target:self 
                                                              selector:@selector(nextExercise:)  
                                                              userInfo:nil 
                                                               repeats:NO];
            
        //answer wrong
        } else {
            if (!self.currentExerciseWrong) {
                self.countWrong = [NSNumber numberWithInt:([self.countWrong intValue] + 1)];
            }
            self.currentExerciseWrong = YES;
            
            //paint button red to show the answer was wrong
            [sender setBackgroundImage:[UIImage imageNamed:@"redcolor.png"] forState:UIControlStateNormal];
        }
    }
}


#pragma mark - Scroll View delegate

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.questionView;
}


#pragma mark - Navigation Controller delegate

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Results"]) {
        [segue.destinationViewController setTrainingResult:(TrainingResult *)sender];
         
    }
}

#pragma mark - View lifecycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self setupProgressBar]; 
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateProgress];
    
    self.questionViewOriginalFrame = self.questionView.frame;
    if (!self.currentExercise) {
        [self nextExercise:self];
    }
    
}

-(void)viewDidUnload
{
    [self setOptionOneButton:nil];
    [self setOptionTwoButton:nil];
    [self setOptionThreeButton:nil];
    [self setOptionFourButton:nil];
    [self setTrainingView:nil];
    [self setTrainingStatusView:nil];
    [self setQuestionScrollView:nil];
    [self setQuestionView:nil];
    [self setCompletionLabel:nil];
    [self setQuestionFlagIconImageView:nil];
    [self setProgessView:nil];
    [self setStopButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
