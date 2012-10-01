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
#import "Logging.h"

#define HEIGHT_OF_ANSWERBUTTONS 37

@interface TrainingViewController () <UIScrollViewDelegate, UITextFieldDelegate>

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
@property (weak, nonatomic) IBOutlet UITextField *answerTextField;

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
@property (nonatomic, strong) UILabel *questionLabel;
@property (nonatomic, strong) NSNumber *countCurrentAnswerWrong;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic) CGRect questionViewOriginalFrame;

@property (nonatomic) BOOL currentExerciseAnswered;
@property (nonatomic) BOOL stopButtonWasPressed;


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
@synthesize openExercises = _openExercises;
@synthesize countDone = _countDone;
@synthesize exerciseCount = _exerciseCount;
@synthesize currentQuestionCorrectAnswerButtons = _currentQuestionCorrectAnswerButtons;
@synthesize answerButtons = _answerButtons;
@synthesize answerTextField = _answerTextField;
@synthesize currentExercise = _currentExercise;
@synthesize currentWord = _currentWord;
@synthesize questionViewOriginalFrame = _questionViewOriginalFrame;
@synthesize countCorrect = _countCorrect;
@synthesize countWrong = _countWrong;
@synthesize currentExerciseWrong = _currentExerciseWrong;
@synthesize timer = _timer;
@synthesize currentTranslations = _currentTranslations;
@synthesize questionLabel = _questionLabel;
@synthesize countCurrentAnswerWrong = _countCurrentAnswerWrong;
@synthesize training = _training;

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

-(void)setTraining:(Training *)training
{
    if (training) {
        _training = training;
        self.openExercises = [training.exercises mutableCopy];
        self.countDone = [NSNumber numberWithInt:0];
        self.exerciseCount = [NSNumber numberWithInt:[self.openExercises count]];
        self.completionLabel.text = [NSString stringWithFormat:@"0 / %i", self.exerciseCount.intValue];
        self.title = self.training.title;
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
    self.progessView.progressTintColor = [UIColor blueColor];
}

-(void)updateFlagIcon
{
    if (self.currentWord.languageCode.intValue == WordLanguageEnglish) {
        self.questionFlagIconImageView.image = [UIImage imageNamed:@"flagUK.png"];
    } else {
        self.questionFlagIconImageView.image = [UIImage imageNamed:@"flagGermany.png"];
    }
}

/*************************************
 Text Input Mode
 Layout views depending on orientation
 *************************************/
- (void)layoutViews
{
    if (self.training.trainingAnswerInputMode == TrainingAnswerInputMode_MultipleChoice) {
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            //Todo: layout buttons 2x2
            int widthOfButtons = (self.trainingView.frame.size.width - ((40) + 8)) / 2;
            self.optionOneButton.frame = CGRectMake(20, 120, widthOfButtons, HEIGHT_OF_ANSWERBUTTONS);
            self.optionTwoButton.frame = CGRectMake(self.optionOneButton.frame.origin.x + widthOfButtons + 8, self.optionOneButton.frame.origin.y, widthOfButtons, HEIGHT_OF_ANSWERBUTTONS);
            self.optionThreeButton.frame = CGRectMake(self.optionOneButton.frame.origin.x, self.optionOneButton.frame.origin.y + HEIGHT_OF_ANSWERBUTTONS + 8, widthOfButtons, HEIGHT_OF_ANSWERBUTTONS);
            self.optionFourButton.frame = CGRectMake(self.optionTwoButton.frame.origin.x, self.optionTwoButton.frame.origin.y + HEIGHT_OF_ANSWERBUTTONS + 8, widthOfButtons, HEIGHT_OF_ANSWERBUTTONS);
        } else {
            //layout buttons 1x4 from bottom
            self.optionFourButton.frame = CGRectMake(20, self.trainingView.frame.size.height - HEIGHT_OF_ANSWERBUTTONS - 20, self.trainingView.frame.size.width - 40, HEIGHT_OF_ANSWERBUTTONS);
            self.optionThreeButton.frame = CGRectMake(20, self.optionFourButton.frame.origin.y - HEIGHT_OF_ANSWERBUTTONS - 8, self.optionFourButton.frame.size.width, HEIGHT_OF_ANSWERBUTTONS);
            self.optionTwoButton.frame = CGRectMake(20, self.optionThreeButton.frame.origin.y - HEIGHT_OF_ANSWERBUTTONS - 8, self.optionFourButton.frame.size.width, HEIGHT_OF_ANSWERBUTTONS);
            self.optionOneButton.frame = CGRectMake(20, self.optionTwoButton.frame.origin.y - HEIGHT_OF_ANSWERBUTTONS - 8, self.optionFourButton.frame.size.width, HEIGHT_OF_ANSWERBUTTONS);
        }
    } else if (self.training.trainingAnswerInputMode == TrainingAnswerInputMode_TextInput) {
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            self.answerTextField.frame = CGRectMake(20, 70, self.trainingView.frame.size.width - 40, 30);
            self.questionScrollView.frame = CGRectMake(20, 35, self.trainingView.frame.size.width - 40, 31);
        } else {
            self.answerTextField.frame = CGRectMake(20, ([UIScreen mainScreen].bounds.size.height == 568 ? 248 : 160), 280, 30);
            self.questionScrollView.frame = CGRectMake(20, ([UIScreen mainScreen].bounds.size.height == 568 ? 132 : 44), 280, 116);
        }
    }
    
    self.questionViewOriginalFrame = self.questionView.frame;
    [self layoutQuestionView];
}


/*************************************
 Mode independent
 Layout the view showing the question
 *************************************/
-(void)layoutQuestionView
{
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        //there is only enough space for one line in landscape mode
        self.questionLabel.numberOfLines = 1;
        
        CGSize maxFrameSize = CGSizeMake(20000, self.questionScrollView.frame.size.height);
        
        CGRect questionFrame = self.questionLabel.frame;
        questionFrame.origin = CGPointMake(0, 0);
        questionFrame.size = [self.questionLabel.text sizeWithFont:self.questionLabel.font constrainedToSize:maxFrameSize lineBreakMode:UILineBreakModeWordWrap];
        
        //Width must be at least the value of the scroll view
        if (questionFrame.size.width < self.questionScrollView.frame.size.width) {
            questionFrame.size.width = self.questionScrollView.frame.size.width;
        }
        
        //Height must be at always the value of the scroll view
        questionFrame.size.height = self.questionScrollView.frame.size.height;
        
        self.questionLabel.frame = questionFrame;
        self.questionView.frame = questionFrame;
        
    } else {
        //there is basically infinite horizontal space
        self.questionLabel.numberOfLines = 0;
        
        CGSize maxFrameSize = CGSizeMake(self.questionScrollView.frame.size.width - 10, 20000);
        CGRect questionFrame = self.questionLabel.frame;
        questionFrame.size = [self.questionLabel.text sizeWithFont:self.questionLabel.font constrainedToSize:maxFrameSize lineBreakMode:UILineBreakModeWordWrap];
        
        //Width must be at least the value of the scroll view
        if (questionFrame.size.width < self.questionScrollView.frame.size.width) {
            questionFrame.size.width = self.questionScrollView.frame.size.width;
        }
        
        //position the question a little bit more from the top if not much text
        if (questionFrame.size.height < (self.questionScrollView.frame.size.height + 20)) {
            questionFrame.origin = CGPointMake(0, 10);
        } else {
            questionFrame.origin = CGPointMake(0, 0);
        }
        
        //assign frame of the text label
        self.questionLabel.frame = questionFrame;
        
        //the surrounding question view frame should start at 0,0 no matter what
        questionFrame.origin = CGPointMake(0, 0);
        
        //assign frame of question view
        self.questionView.frame = questionFrame;
    }
    
        
    self.questionScrollView.contentSize = self.questionView.frame.size;
}

/*************************************
 Mode independent
 Update question with new one
 *************************************/
-(void)updateQuestion
{
    //remove all subviews in case this viewController instance has been used before
    for (UIView *subview in self.questionView.subviews) {
        [subview removeFromSuperview];
    }
    
    //Title (searched word)
    self.questionLabel = [[UILabel alloc] init];
    self.questionLabel.text = self.currentWord.name;
    //self.questionLabel.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
    self.questionLabel.font = [UIFont boldSystemFontOfSize:22];
    self.questionLabel.textAlignment = UITextAlignmentCenter;
    self.questionLabel.backgroundColor = [UIColor clearColor];
    self.questionLabel.lineBreakMode = UILineBreakModeWordWrap;
    
    [self layoutQuestionView];
    [self.questionView addSubview:self.questionLabel];
}

/*************************************
 Multiple Choice Mode
 Update all buttons with new answers
 *************************************/
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

/*************************************
 Mode independent
 Update progress bar on top
 *************************************/
-(void)updateProgress
{
    self.completionLabel.text = [NSString stringWithFormat:@"%i / %i", [self.countDone intValue], [self.exerciseCount intValue]];
    
    [self.progessView setProgress:([self.countDone floatValue] / [self.exerciseCount floatValue]) animated:YES];
}

/*************************************
 Mode independent
 Create and show results
 *************************************/
-(void)showResults
{
    TrainingResultsViewController *resultsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Training Results"];
    resultsVC.training = self.training;
    
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

/*************************************
 Mode independent
 Finish training (no more exercises)
 *************************************/
-(void)completeTraining
{
    for (UIButton *button in self.answerButtons) {
        button.enabled = NO;
    }
    
    if (self.training.trainingResultsObjectId) {
        self.training.trainingResult = [[DictVocTrainer instance] trainingResultWithObjectId:self.training.trainingResultsObjectId];
    }
    
    if (!self.training.trainingResult) {
        self.training.trainingResult = [[DictVocTrainer instance] insertTrainingResultWithCountWrong:self.countWrong countCorrect:self.countCorrect countWords:self.exerciseCount collection:self.training.collection trainingDate:[NSDate date]];
    }
    [self showResults];
}

/*************************************
 Text Input Mode
 Reset text input for a new answer
 *************************************/
-(void)updateTextInputForNewQuestion
{
    self.answerTextField.textColor = [UIColor blackColor];
    self.answerTextField.font = [UIFont systemFontOfSize:17.0];
    self.answerTextField.enabled = YES;
    self.answerTextField.text = @"";
    self.answerTextField.backgroundColor = [UIColor whiteColor];
    [self.answerTextField becomeFirstResponder];
}


/*************************************
 Text Input Mode
 Answer Handling
 *************************************/
-(void)processTextInputAnswer
{

    
    //determine if answer is correct or wrong
    bool answerIsCorrect = false;
    NSString *normalizedAnswer = [[self.answerTextField.text lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    SQLiteWord *fullAnswerWord = nil;
    for (SQLiteWord *answerWord in self.currentWord.translations) {
        
        float lengthOfAnswerWord = answerWord.nameWithoutBracketInfo.length;
        float lengthOfUserAnswer = normalizedAnswer.length;
        
        if (lengthOfUserAnswer / lengthOfAnswerWord >= DVT_MIN_WORDLENGTH_CORRECT_PERCENTAGE) {
            if ([[answerWord.nameWithoutContextInfo lowercaseString] rangeOfString:normalizedAnswer].location != NSNotFound) {
                fullAnswerWord = answerWord;
                answerIsCorrect = true;
                break;
            }
        }
    }
    
    //handle result
    if (answerIsCorrect) {
        /*****************************************
         Special hanling for text input mode
         *****************************************/
        self.answerTextField.backgroundColor = [UIColor greenColor];
        self.answerTextField.text = fullAnswerWord.name;
        [self.answerTextField becomeFirstResponder];
        
        //scroll to the left (this is a workaround moving the cursor to the very left)
        [self moveCursorInTextFieldToBeginning:self.answerTextField];
        
        self.countCurrentAnswerWrong = [NSNumber numberWithInt:0];
        
        /*****************************************
         General correct answer handling
         *****************************************/
        [self processCorrectAnswerGeneral];
        self.currentExerciseAnswered = YES;
        
    } else {
        /*****************************************
         General wrong answer handling
         *****************************************/
        [self.answerTextField becomeFirstResponder];
        [self processWrongAnswerGeneral];
        
        /*****************************************
         Special hanling for text input mode
         *****************************************/
        //Save one more wrong for current answers
        self.countCurrentAnswerWrong = [NSNumber numberWithInt:([self.countCurrentAnswerWrong intValue] + 1)];
        
        if (self.countCurrentAnswerWrong.intValue >= 2) {
            //show correct answer and go on
            int countAvailableCorrectAnswers = [self.currentWord.translations count];
            int randomIndexOfACorrectAnswer = arc4random_uniform(countAvailableCorrectAnswers - 1);
            
            self.answerTextField.text = ((SQLiteWord *)[self.currentWord.translations objectAtIndex:randomIndexOfACorrectAnswer]).nameWithoutContextInfo;
            self.answerTextField.textColor = [UIColor whiteColor];
            self.answerTextField.font = [UIFont boldSystemFontOfSize:17.0];
            self.answerTextField.enabled = NO;
            self.answerTextField.backgroundColor = [UIColor redColor];//colorWithWhite:0.8 alpha:1.0];
            
            //scroll to the left (this is a workaround moving the cursor to the very left)
            [self moveCursorInTextFieldToBeginning:self.answerTextField];
            
            //reset countCurrentAnswerWrong
            self.countCurrentAnswerWrong = [NSNumber numberWithInt:0];

            //only remove this word from current training if training mode is set to dismiss (not repeat)
            if (self.training.trainingWrongAnswerHandlingMode == TrainingWrongAnswerHandlingMode_Dismiss) {
                //remove solved exercise from open list
                [self.openExercises removeObject:self.currentExercise];
                
                //add to done
                self.countDone = [NSNumber numberWithInt:([self.countDone intValue] + 1)];
            }
            
            //update progress
            [self updateProgress];
            
            self.currentExerciseAnswered = YES;
            
            //go to next exercise after 2 second
            self.timer = [NSTimer scheduledTimerWithTimeInterval:DVT_WAITSECONDS_FOR_TRAINING_NEXT_IF_WRONG
                                                          target:self
                                                        selector:@selector(nextExercise:)
                                                        userInfo:nil
                                                         repeats:NO];
            
            
        } else {
            self.answerTextField.backgroundColor = [UIColor redColor];
            self.currentExerciseAnswered = NO;
        }
    }
    
    //save to database (countWrong, countCorrect, ...)
    [[DictVocTrainer instance] saveDictVocTrainerDBUsingBlock:^(NSError *error) {
        if (error) {
            LogError(@"Error saving success rate of word");
        }
    }];
}

-(void)moveCursorInTextFieldToBeginning:(UITextField *)textField
{
    if ([self.answerTextField.text sizeWithFont:self.answerTextField.font constrainedToSize:CGSizeMake(20000, 30) lineBreakMode:UILineBreakModeWordWrap].width > (self.answerTextField.frame.size.width - 10)) {
        UITextRange *selectedRange = textField.selectedTextRange;
        UITextPosition *newPosition = [textField positionFromPosition:selectedRange.start offset:(0 - textField.text.length)];
        UITextRange *newRange = [textField textRangeFromPosition:newPosition toPosition:newPosition];
        [textField setSelectedTextRange:newRange];
    }
}

/*************************************
 Mode Independent
 Answer Handling (correct answer)
 *************************************/
-(void)processCorrectAnswerGeneral
{
    //add 1 one the correct answers & success rate
    if (!self.currentExerciseWrong) {
        self.countCorrect = [NSNumber numberWithInt:([self.countCorrect intValue] + 1)];
        self.currentExercise.countCorrect = [NSNumber numberWithInt:self.currentExercise.countCorrect.intValue + 1];
        self.currentExercise.exerciseCount = [NSNumber numberWithInt:self.currentExercise.exerciseCount.intValue + 1];
    }
    
    //only remove this word from current training if it was correct or wrong and training mode is set to dismiss (not repeat)
    if (!self.currentExerciseWrong ||
        (self.currentExerciseWrong && (self.training.trainingWrongAnswerHandlingMode == TrainingWrongAnswerHandlingMode_Dismiss))) {
        //add to done
        self.countDone = [NSNumber numberWithInt:([self.countDone intValue] + 1)];
        
        //remove solved exercise from open list
        [self.openExercises removeObject:self.currentExercise];
    }
    
    //update progress
    [self updateProgress];
    
    //go to next exercise after 1 second
    self.timer = [NSTimer scheduledTimerWithTimeInterval:DVT_WAITSECONDS_FOR_TRAINING_NEXT
                                                  target:self
                                                selector:@selector(nextExercise:)
                                                userInfo:nil
                                                 repeats:NO];
}

/*************************************
 Mode Independent
 Answer Handling (wrong answer)
 *************************************/
-(void)processWrongAnswerGeneral
{
    //Save one more wrong for stats & success rate
    if (!self.currentExerciseWrong) {
        self.countWrong = [NSNumber numberWithInt:([self.countWrong intValue] + 1)];
        self.currentExercise.countWrong = [NSNumber numberWithInt:self.currentExercise.countWrong.intValue + 1];
        self.currentExercise.exerciseCount = [NSNumber numberWithInt:self.currentExercise.exerciseCount.intValue + 1];
    }
    
    //state that this answer was wrong
    self.currentExerciseWrong = YES;
}

-(void)showHelp
{
    if (self.training.trainingAnswerInputMode == TrainingAnswerInputMode_MultipleChoice) {
        [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_TRAINING_MULTIPLE_CHOICE", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES pointingToView:optionOneButton fromDirection:FWToastViewPointingFromDirectionTop];
    } else if ((self.training.trainingAnswerInputMode == TrainingAnswerInputMode_TextInput) && UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_TRAINING_TYPE_ANSWER", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES pointingToView:self.answerTextField fromDirection:FWToastViewPointingFromDirectionTop];
    }
}


#pragma mark - Target / Action

- (IBAction)stopButtonPressed:(id)sender {
    self.stopButtonWasPressed = YES;
    [self completeTraining];
}

/*************************************
 Mode independent
 Next Exercise
 *************************************/
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
        
        if (self.training.trainingAnswerInputMode == TrainingAnswerInputMode_MultipleChoice) {
            [self updateButtons];
        } else if (self.training.trainingAnswerInputMode == TrainingAnswerInputMode_TextInput) {
            self.currentExerciseAnswered = NO;
            [self updateTextInputForNewQuestion];
        }
    }
}


/*************************************
 Multiple Choice Mode
 Answer Handling
 *************************************/
-(IBAction)optionButtonPressed:(UIButton *)sender 
{
    if (![self.timer isValid]) {
        //answer correct
        if ([self.currentQuestionCorrectAnswerButtons containsObject:sender]) {
            
            //paint button green to show the answer was correct
            [sender setBackgroundImage:[UIImage imageNamed:@"greencolor.png"] forState:UIControlStateNormal];
            
            [self processCorrectAnswerGeneral];
            
        //answer wrong
        } else {

            //paint button red to show the answer was wrong
            [sender setBackgroundImage:[UIImage imageNamed:@"redcolor.png"] forState:UIControlStateNormal];
            
            [self processWrongAnswerGeneral];
        }
        
        //save to database (countWrong, countCorrect, ...)
        [[DictVocTrainer instance] saveDictVocTrainerDBUsingBlock:^(NSError *error) {
            if (error) {
                LogError(@"Error saving success rate of word");
            }
        }];
    }
}


#pragma mark - UITextFieldDelegate

//if the user pressed "done" it will resign, so the user cannot add enters into the text
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([self.timer isValid]) {
        return FALSE;
    }
    
    //return if done pressed
    if ([string isEqualToString:@"\n"]) {
        
        [textField resignFirstResponder];
        return FALSE;
    }
    
    return TRUE;
}

//usually called if the user pressed return to check if his answer is correct, but also on ViewWillDisappear!
-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if (!self.currentExerciseAnswered && !([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) && !self.stopButtonWasPressed) {
        [self processTextInputAnswer];
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
        [segue.destinationViewController setTraining:self.training];
         
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
    
    //trainingMode
    if (self.training.trainingAnswerInputMode == TrainingAnswerInputMode_MultipleChoice) {
        self.answerTextField.hidden = YES;
        self.answerTextField.enabled = NO;
    } else if (self.training.trainingAnswerInputMode == TrainingAnswerInputMode_TextInput) {
        for (UIButton *answerButton in self.answerButtons) {
            answerButton.hidden = YES;
            self.answerTextField.enabled = YES;
        }
    }
    
    [self updateProgress];
    
    self.questionViewOriginalFrame = self.questionView.frame;
    if (!self.currentExercise) {
        [self nextExercise:self];
    }
    
    self.stopButtonWasPressed = NO;
    
    [self layoutViews];
}

-(void)viewWillDisappear:(BOOL)animated
{
    if (self.training.trainingAnswerInputMode == TrainingAnswerInputMode_TextInput) {
        [self.view endEditing:YES];
    }
    
    [super viewWillDisappear:animated];
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
    [self setAnswerTextField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self layoutViews];
}

@end
