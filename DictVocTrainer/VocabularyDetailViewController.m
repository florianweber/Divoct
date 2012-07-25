/*
VocabularyDetailViewController.m
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
#import "VocabularyDetailViewController.h"
#import "VocabularyDetailView.h"
#import "DictVocDictionary.h"
#import "DictVocTrainer.h"
#import "CollectionChooserTableViewController.h"
#import "GlobalDefinitions.h"
#import "FWToastView.h"
#import "Translation.h"
#import "Exercise+Extended.h"

@interface VocabularyDetailViewController() <UIScrollViewDelegate, VocabularyDetailsViewDatasource>

@property (nonatomic, strong) SQLiteWord *word;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet VocabularyDetailView *vocabularyDetailView;
@property (weak, nonatomic) IBOutlet UIButton *searchWikipediaButton;
@property (weak, nonatomic) IBOutlet UIButton *searchGoogleButton;
@property (nonatomic, strong) NSMutableArray *translationLabels;
@property (nonatomic, strong) NSMutableArray *translationButtons;
@property (nonatomic, strong) UILabel *wordLabel;
@property (nonatomic, strong) UIButton *editTranslationsButton;
@property (nonatomic) BOOL showEditingOnAppear;

- (IBAction)organizeButtonPressed:(id)sender;

@end


@implementation VocabularyDetailViewController
@synthesize exercise = _exercise;
@synthesize scrollView;
@synthesize vocabularyDetailView;
@synthesize searchWikipediaButton = _searchWikipediaButton;
@synthesize searchGoogleButton = _searchGoogleButton;
@synthesize word = _word;
@synthesize hideCollection = _hideCollection;
@synthesize editTrainingTranslationsButtonEnabled = _editTrainingTranslationsButtonEnabled;
@synthesize translationLabels = _translationLabels;
@synthesize wordLabel = _wordLabel;
@synthesize editTranslationsButton = _editTranslationsButton;
@synthesize translationButtons = _translationButtons;
@synthesize showEditingOnAppear = _showEditingOnAppear;

#pragma mark - Getter / Setter

-(void)setExercise:(Exercise *)exercise
{
    if (exercise != _exercise) {
        _exercise = exercise;
        self.word = exercise.word;
    }
}

-(void)setWord:(SQLiteWord *)word
{
    if (word != _word) {
        if (!word.translations || [word.translations count] == 0) {
            _word = [[DictVocDictionary instance] getRelationsShipsForWord:word];
        } else {
            _word = word;
        }
        self.title = word.name;
    }
}

-(UIButton *)editTranslationsButton
{
    if (!_editTranslationsButton) {
        _editTranslationsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_editTranslationsButton addTarget:self action:@selector(editTrainingTranslationsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [_editTranslationsButton setBackgroundColor:[UIColor clearColor]];
        [_editTranslationsButton setImage:[UIImage imageNamed:@"edit_gradhat.png"] forState:UIControlStateNormal];
    }
    return _editTranslationsButton;
}

-(NSMutableArray *)translationLabels
{
    if (!_translationLabels) {
        _translationLabels = [[NSMutableArray alloc] init];
    }
    return _translationLabels;
}

-(NSMutableArray *)translationButtons
{
    if (!_translationButtons) {
        _translationButtons = [[NSMutableArray alloc] init];
    }
    return _translationButtons;
}


#pragma mark - My messages

-(void)setupVocabularyDetailsView
{
    //remove all subviews in case this viewController instance has been used before
    for (UIView *subview in self.vocabularyDetailView.subviews) {
        [subview removeFromSuperview];
    }
    [self.translationLabels removeAllObjects];
    
    [self addLabels];
    
    self.scrollView.contentSize = self.vocabularyDetailView.frame.size;
}


-(void)addLabels
{
    CGPoint lastOrigin;
    CGSize lastSize;
    CGFloat paddingY = 3;
    
    //Start point top left
    CGPoint descStart;
    descStart.x = 10;
    descStart.y = 10;
    
    CGSize maxFrameSizeWoEditButton     = CGSizeMake(self.vocabularyDetailView.frame.size.width - descStart.x, 20000);
    CGSize maxFrameSizeWithEditButton   = maxFrameSizeWoEditButton;
    
    //Title (searched word)
    UILabel *wordLabel = [[UILabel alloc] init];
    wordLabel.text = self.word.name;
    if (self.word.grammarInfo) {
        wordLabel.text = [wordLabel.text stringByAppendingFormat:@" %@", self.word.grammarInfo];
    }
    
    wordLabel.font = [UIFont boldSystemFontOfSize:26];
    wordLabel.backgroundColor = [UIColor clearColor];
    wordLabel.numberOfLines = 0;
    wordLabel.lineBreakMode = UILineBreakModeWordWrap;
    
    CGRect wordFrame = wordLabel.frame;
    wordFrame.origin = descStart;
    wordFrame.size = [wordLabel.text sizeWithFont:wordLabel.font constrainedToSize:maxFrameSizeWoEditButton lineBreakMode:UILineBreakModeWordWrap];

    wordLabel.frame = wordFrame;
    lastOrigin = wordLabel.frame.origin;
    lastSize = wordFrame.size;
    
    self.wordLabel = wordLabel;
    [self.vocabularyDetailView addSubview:wordLabel];
    
    //Edit Translations Button
    if (self.editTrainingTranslationsButtonEnabled) {
        CGRect buttonFrame = self.editTranslationsButton.frame;
        buttonFrame.size = CGSizeMake(22, 22);
        
        if (wordLabel.frame.origin.x + wordLabel.frame.size.width + descStart.x + buttonFrame.size.width + descStart.x > self.vocabularyDetailView.frame.size.width) {
            //put the button to the right end of the screen
            buttonFrame.origin = CGPointMake(self.vocabularyDetailView.frame.size.width - buttonFrame.size.width - descStart.x, descStart.y + 4);
            
            //adjust wordLabel.frame (make it shorter)
            maxFrameSizeWithEditButton = CGSizeMake(self.vocabularyDetailView.frame.size.width - descStart.x - self.editTranslationsButton.frame.size.width - descStart.x, 20000);
            wordFrame.size = [wordLabel.text sizeWithFont:wordLabel.font constrainedToSize:maxFrameSizeWithEditButton lineBreakMode:wordLabel.lineBreakMode];
            wordLabel.frame = wordFrame;
            lastSize = wordFrame.size;
        } else {
            //put the button to the right of the wordLabel
            buttonFrame.origin = CGPointMake(wordLabel.frame.origin.x + wordLabel.frame.size.width + descStart.x, descStart.y + 4);
        }
        
        self.editTranslationsButton.frame = buttonFrame;
        [self.vocabularyDetailView addSubview:_editTranslationsButton];
        
        maxFrameSizeWithEditButton   = CGSizeMake(self.vocabularyDetailView.frame.size.width - descStart.x - self.editTranslationsButton.frame.size.width - descStart.x - descStart.x, 20000);
    }
    
    
    //Translations
    //------------------------------------
    
    int translationCount = self.word.translations.count;
    if (translationCount > 0) {
        
        SQLiteWord *translation = [self.word.translations objectAtIndex:0];
        
        UILabel *firstTranslationLabel = [[UILabel alloc] init];
        firstTranslationLabel.text = translation.name;
        firstTranslationLabel.font = [UIFont systemFontOfSize:18];
        firstTranslationLabel.backgroundColor = [UIColor clearColor];
        firstTranslationLabel.numberOfLines = 0;
        firstTranslationLabel.lineBreakMode = UILineBreakModeWordWrap;
        firstTranslationLabel.userInteractionEnabled = YES;
        [firstTranslationLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(labelPressed:)]];
        
        CGRect translationFrame = firstTranslationLabel.frame;
        translationFrame.origin = lastOrigin;
        translationFrame.origin.x = lastOrigin.x + descStart.x;
        translationFrame.origin.y = lastOrigin.y + lastSize.height + paddingY + 3;
        translationFrame.size = [firstTranslationLabel.text sizeWithFont:firstTranslationLabel.font constrainedToSize:maxFrameSizeWoEditButton lineBreakMode:UILineBreakModeWordWrap];
        if (CGRectIntersectsRect(translationFrame, self.editTranslationsButton.frame)) {
            translationFrame.size = [firstTranslationLabel.text sizeWithFont:firstTranslationLabel.font constrainedToSize:maxFrameSizeWithEditButton lineBreakMode:firstTranslationLabel.lineBreakMode];
        }
        
        
        firstTranslationLabel.frame = translationFrame;
        
        lastOrigin = translationFrame.origin;
        lastSize = translationFrame.size;
        
        [self.translationLabels addObject:firstTranslationLabel];
        [self.vocabularyDetailView addSubview:firstTranslationLabel];
        
        for (int i=1; i<translationCount; i++) {
            translation = [self.word.translations objectAtIndex:i];
            
            UILabel *translationLabel = [[UILabel alloc] init];
            translationLabel.text = translation.name;
            translationLabel.font = [UIFont systemFontOfSize:18];
            translationLabel.backgroundColor = [UIColor clearColor];
            translationLabel.numberOfLines = 0;
            translationLabel.lineBreakMode = UILineBreakModeWordWrap;
            translationLabel.userInteractionEnabled = YES;
            [translationLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(labelPressed:)]];
            
            translationFrame = translationLabel.frame;
            translationFrame.origin = lastOrigin;
            translationFrame.origin.y = lastOrigin.y + lastSize.height + paddingY;
            translationFrame.size = [translationLabel.text sizeWithFont:translationLabel.font constrainedToSize:maxFrameSizeWoEditButton lineBreakMode:UILineBreakModeWordWrap];
            if (CGRectIntersectsRect(translationFrame, self.editTranslationsButton.frame)) {
                translationFrame.size = [translationLabel.text sizeWithFont:translationLabel.font constrainedToSize:maxFrameSizeWithEditButton lineBreakMode:translationLabel.lineBreakMode];
            }
            
            translationLabel.frame = translationFrame;
            lastOrigin = translationFrame.origin;
            lastSize = translationFrame.size;
            
            [self.translationLabels addObject:translationLabel];
            [self.vocabularyDetailView addSubview:translationLabel];
        }
        
        //change vocabularyDetailView.frame to fit the subviews' size
        CGFloat contentHeight = lastOrigin.y + lastSize.height + 20;
        if (contentHeight > self.vocabularyDetailView.frame.size.height) {
            CGSize sizeFittingSubviews = CGSizeMake(self.vocabularyDetailView.frame.size.width, contentHeight);
            
            CGRect newFrame = self.vocabularyDetailView.frame;
            newFrame.size = sizeFittingSubviews;
            self.vocabularyDetailView.frame = newFrame;
        }
    }
}

-(void)toggleEditButtonState
{
    if (self.editTranslationsButton.selected) {
        self.editTranslationsButton.highlighted = NO;
        self.editTranslationsButton.selected = NO;
    } else {
        self.editTranslationsButton.highlighted = YES;
        self.editTranslationsButton.selected = YES;
    }
}

-(void)layoutForEditingTranslations
{
    //hide editing view
    if (self.editTranslationsButton.selected) {
        
        CGSize maxFrameSizeWoEditButton     = CGSizeMake(self.vocabularyDetailView.frame.size.width - 10, 20000);
        CGSize maxFrameSizeWithEditButton   = CGSizeMake(self.vocabularyDetailView.frame.size.width - 10 - self.editTranslationsButton.frame.size.width - 10, 20000);
        
        for (UIButton *button in self.translationButtons) {
            NSUInteger index = [self.translationButtons indexOfObject:button];
            UILabel *translationLabel = [self.translationLabels objectAtIndex:index];
            translationLabel.lineBreakMode = UILineBreakModeWordWrap;
            CGRect translationFrame = translationLabel.frame;
            translationFrame.size = [translationLabel.text sizeWithFont:translationLabel.font constrainedToSize:maxFrameSizeWoEditButton lineBreakMode:UILineBreakModeWordWrap];
            if (CGRectIntersectsRect(translationFrame, self.editTranslationsButton.frame)) {
                translationFrame.size = [translationLabel.text sizeWithFont:translationLabel.font constrainedToSize:maxFrameSizeWithEditButton lineBreakMode:translationLabel.lineBreakMode];
            }
            
            translationLabel.frame = translationFrame;
            [button removeFromSuperview];
        }
        [self.translationButtons removeAllObjects];
        
    //show editing view
    } else {
    
        if (![self.exercise.trainingTranslations count]) {
            for (SQLiteWord *translationWord in self.word.translations) {
                Translation *translation = [[DictVocTrainer instance] translationWithUniqueId:translationWord.uniqueId]; 
                [translation addExercisesObject:self.exercise];
            }
            [[DictVocTrainer instance] saveDictVocTrainerDBUsingBlock:^(NSError *error){}];
        }        
        
        int checkmarkButtonWidth = 20;
        int buttonStartX = 0;
        for (UILabel *label in self.translationLabels) {
            buttonStartX = MAX(buttonStartX, (label.frame.origin.x + label.frame.size.width));
        }
        buttonStartX += 20;
        if (buttonStartX > self.vocabularyDetailView.frame.size.width - 10 - checkmarkButtonWidth) {
            buttonStartX = self.vocabularyDetailView.frame.size.width - 10 - checkmarkButtonWidth;
        }
        
        for (UILabel *label in self.translationLabels) {
            //prepare checkmark
            UIButton *checkmarkButton = [[UIButton alloc] init];
            [checkmarkButton addTarget:self action:@selector(toggleTrainerTranslation:) forControlEvents:UIControlEventTouchUpInside];
            [checkmarkButton setImage:[UIImage imageNamed:@"ios_checkmark_checked.png"] forState:UIControlStateSelected];
            [checkmarkButton setImage:[UIImage imageNamed:@"ios_checkmark_empty.png"] forState:UIControlStateNormal];            
            CGRect checkmarkButtonFrame = CGRectMake(buttonStartX, label.frame.origin.y, checkmarkButtonWidth, checkmarkButtonWidth);
            checkmarkButton.frame = checkmarkButtonFrame;

            //select button (or not)
            Translation *translation = [[DictVocTrainer instance] translationWithUniqueId:((SQLiteWord *)[self.word.translations objectAtIndex:[self.translationLabels indexOfObject:label]]).uniqueId];
            if ([self.exercise.trainingTranslations containsObject:translation]) {
                checkmarkButton.selected = YES;
            }
            
            [self.translationButtons addObject:checkmarkButton];
            
            //prepare label frame changes
            label.lineBreakMode = UILineBreakModeTailTruncation;
            int labelAbsoluteMaxX = label.frame.origin.x + label.frame.size.width + 10;
            CGRect newLabelFrame = label.frame;
            if (labelAbsoluteMaxX > checkmarkButton.frame.origin.x) {
                newLabelFrame.size = CGSizeMake(labelAbsoluteMaxX - (labelAbsoluteMaxX - checkmarkButton.frame.origin.x) - label.frame.origin.x, label.frame.size.height);
            }
            
            //apply to view
            label.frame = newLabelFrame;
            [self.vocabularyDetailView addSubview:checkmarkButton];
            
        }
    }
}

-(void)toggleEditing
{
    [self layoutForEditingTranslations];
    [self toggleEditButtonState];
}

-(void)showHelp
{
    if (self.editTranslationsButton.selected) {
        [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_TRANSLATIONS_EDIT_SELECTOR", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES pointingToView:[self.translationButtons objectAtIndex:0] fromDirection:FWToastViewPointingFromDirectionBottom];
    } else {
        [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_TRANSLATIONS_EDIT_BUTTON", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES pointingToView:self.editTranslationsButton fromDirection:FWToastViewPointingFromDirectionBottom];
    }
}

-(void)addSwipeGestureRecognizer
{
    UISwipeGestureRecognizer *rightSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                                 action:@selector(handleSwipeFrom:)];
    rightSwiper.direction = UISwipeGestureRecognizerDirectionRight;
    [self.vocabularyDetailView addGestureRecognizer:rightSwiper];
    
    UISwipeGestureRecognizer *leftSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                                      action:@selector(handleSwipeFrom:)];
    leftSwiper.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.vocabularyDetailView addGestureRecognizer:leftSwiper];
}

-(void)addTapGestureRecognizer
{
    //Double Tap
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleEditing)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self.vocabularyDetailView addGestureRecognizer:doubleTapGestureRecognizer];
}

#pragma mark - VocabularyDetailsView dataSource 

-(SQLiteWord *)getWord
{
    return self.word;
}


#pragma mark - Scroll View delegate

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return vocabularyDetailView;
}

#pragma mark - Navigation Controller Delegate

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Organize in Collections"]) {
        [segue.destinationViewController setWord:self.word];
        [segue.destinationViewController setHideCollection:self.hideCollection];
    }
}

#pragma mark - Target / Action

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        [self organizeButtonPressed:self];
    } else if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        [[self navigationController] popViewControllerAnimated:YES];
    }
}
         
- (IBAction)editTrainingTranslationsButtonPressed:(UIButton *)sender 
{
    [self layoutForEditingTranslations];
    [self performSelector:@selector(toggleEditButtonState) withObject:nil afterDelay:0.0];
}

- (IBAction)toggleTrainerTranslation:(UIButton *)sender
{
    Translation *translation = [[DictVocTrainer instance] translationWithUniqueId:((SQLiteWord *)[self.word.translations objectAtIndex:[self.translationButtons indexOfObject:sender]]).uniqueId];
    
    if (sender.selected) {
        if ([self.exercise.trainingTranslations count] == 1) {
            [FWToastView toastInView:self.view.superview withText:NSLocalizedString(@"TRANSLATIONS_EDIT_MIN_ONE", nil) icon:FWToastViewIconWarning duration:FWToastViewDurationDefault withCloseButton:YES];
        } else {
            sender.selected = NO;
            [translation removeExercisesObject:self.exercise];
            [[DictVocTrainer instance] saveDictVocTrainerDBUsingBlock:^(NSError *error){}];
        }
        
    } else {
        sender.selected = YES;
        [translation addExercisesObject:self.exercise];
        [[DictVocTrainer instance] saveDictVocTrainerDBUsingBlock:^(NSError *error){}];
    }
}

- (IBAction)labelPressed:(UIGestureRecognizer *)sender
{
    if (self.editTranslationsButton.selected) {
        [self toggleTrainerTranslation:[self.translationButtons objectAtIndex:[self.translationLabels indexOfObject:sender.view]]];
    } else {
        //load word and exercise
        SQLiteWord *word = [self.word.translations objectAtIndex:[self.translationLabels indexOfObject:sender.view]];
        Exercise *exercise = [[DictVocTrainer instance] exerciseWithWordUniqueId:word.uniqueId];
        [exercise addCollectionsObject:[[DictVocTrainer instance] collectionWithName:NSLocalizedString(@"RECENTS_TITLE", nil)]];
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:DVT_COLLECTION_NOTIFICATION_CONTENTS_CHANGED object:nil]];

        //create another view controller like this
        VocabularyDetailViewController *vocDetVC = [self.storyboard instantiateViewControllerWithIdentifier:@"VocabularyDetail"];
        [vocDetVC setExercise:exercise];
        [vocDetVC setEditTrainingTranslationsButtonEnabled:YES];
        
        //go there
        [self.navigationController pushViewController:vocDetVC animated:YES];
    }
}

- (IBAction)organizeButtonPressed:(id)sender {
    
    [self performSegueWithIdentifier:@"Organize in Collections" sender:sender];
}

- (IBAction)searchWikiButtonPressed:(UIButton *)sender {
    NSString *language;
    NSString *searchTerm = self.word.name;
    
    switch ([self.word.languageCode intValue]) {
        case WordLanguageGerman:
            language = @"de";
            break;
            
        case WordLanguageEnglish:
            language = @"en";
            break;
            
        default:
            language = @"en";
            break;
    }
    
    NSString* launchUrl = [[NSString stringWithFormat:@"http://www.wikipedia.org/search-redirect.php?language=%@&search=%@", language, searchTerm] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: launchUrl]];
}

- (IBAction)searchGoogleButtonPressed:(UIButton *)sender {
    NSString *language;
    NSString *googleSiteEnding;
    NSString *searchTerm = self.word.name;
    
    //todo: should be changed to user language
    switch ([self.word.languageCode intValue]) {
        case WordLanguageGerman:
            language = @"de";
            googleSiteEnding = @"de";
            break;
            
        case WordLanguageEnglish:
            language = @"en";
            googleSiteEnding = @"com";
            break;
            
        default:
            language = @"en";
            googleSiteEnding = @"com";
            break;
    }
    
    NSString* launchUrl = [[NSString stringWithFormat:@"http://www.google.%@/search?rls=%@&q=%@&ie=UTF-8&oe=UTF-8", googleSiteEnding, language, searchTerm] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: launchUrl]];
}




#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    vocabularyDetailView.dataSource = self;
    [self addSwipeGestureRecognizer];
    [self addTapGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupVocabularyDetailsView];
    if (self.showEditingOnAppear) {
        [self toggleEditing];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //disable edit mode if enabled
    if (self.editTranslationsButton.selected) {
        [self toggleEditing];
        self.showEditingOnAppear = YES;
    } else {
        self.showEditingOnAppear = NO;
    }
    
}

- (void)viewDidUnload
{
    [self setVocabularyDetailView:nil];
    [self setScrollView:nil];
    [self setSearchWikipediaButton:nil];
    [self setSearchGoogleButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
