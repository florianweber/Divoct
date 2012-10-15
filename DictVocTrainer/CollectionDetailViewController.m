/*
CreateCollectionViewController.m
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


#import "CollectionDetailViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "GlobalDefinitions.h"
#import "Logging.h"
#import "FWToastView.h"
#import "DictVocTrainer.h"

#define kOFFSET_FOR_KEYBOARD_PORTRAIT 80.0
#define kOFFSET_FOR_KEYBOARD_LANDSCAPE 50.0

@interface CollectionDetailViewController () <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *titleInputBox;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionInputBox;
@property (weak, nonatomic) IBOutlet UILabel *errorMessageLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *bottomBarTitleButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *finishButton;
@property (nonatomic) BOOL viewIsMovedUp;

@end

@implementation CollectionDetailViewController
@synthesize titleInputBox;
@synthesize descriptionInputBox;
@synthesize errorMessageLabel;
@synthesize bottomBarTitleButton;
@synthesize cancelButton;
@synthesize finishButton;
@synthesize delegate = _delegate;
@synthesize collection = _collection;
@synthesize importantChanges = _importantChanges;
@synthesize viewIsMovedUp = _viewIsMovedUp;

#pragma mark - My Messages

- (void)layoutViews
{
    BOOL fourInch = ([UIScreen mainScreen].bounds.size.height == 568);
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        
        CGRect titleLabelFrame = CGRectMake(20, 180, 151, 21);
        self.titleLabel.frame = titleLabelFrame;
        self.titleLabel.textAlignment = UITextAlignmentLeft;
        
        CGRect titleInputBoxFrame = CGRectMake(20, 204, 280, 29);
        self.titleInputBox.frame = titleInputBoxFrame;
        self.titleInputBox.textAlignment = UITextAlignmentLeft;
        
        CGRect descriptionLabelFrame = CGRectMake(20, 240, 235, 21);
        self.descriptionLabel.frame = descriptionLabelFrame;
        self.descriptionLabel.textAlignment = UITextAlignmentLeft;
        
        CGRect descriptionInputBoxFrame = CGRectMake(20, 264, 280, 56);
        self.descriptionInputBox.frame = descriptionInputBoxFrame;
        self.descriptionInputBox.textAlignment = UITextAlignmentLeft;
        
        CGRect errorMessageLabelFrame = CGRectMake(20, 337, 280, 50);
        self.errorMessageLabel.frame = errorMessageLabelFrame;
        self.errorMessageLabel.textAlignment = UITextAlignmentCenter;
        
    } else {
        CGRect titleLabelFrame = CGRectMake((fourInch ? 400 : 312), 40, 151, 21);
        self.titleLabel.frame = titleLabelFrame;
        self.titleLabel.textAlignment = UITextAlignmentRight;
        
        CGRect titleInputBoxFrame = CGRectMake((fourInch ? 271 : 183), 64, 280, 29);
        self.titleInputBox.frame = titleInputBoxFrame;
        self.titleInputBox.textAlignment = UITextAlignmentRight;
        
        CGRect descriptionLabelFrame = CGRectMake((fourInch ? 316 : 228), 100, 235, 21);
        self.descriptionLabel.frame = descriptionLabelFrame;
        self.descriptionLabel.textAlignment = UITextAlignmentRight;
        
        CGRect descriptionInputBoxFrame = CGRectMake((fourInch ? 150 : 62), 124, 400, 56);
        self.descriptionInputBox.frame = descriptionInputBoxFrame;
        self.descriptionInputBox.textAlignment = UITextAlignmentRight;
        
        CGRect errorMessageLabelFrame = CGRectMake((fourInch ? 150 : 62), 185, 400, 50);
        self.errorMessageLabel.frame = errorMessageLabelFrame;
        self.errorMessageLabel.textAlignment = UITextAlignmentRight;
    }
}

- (void)setupTitleInputBox
{
    self.titleInputBox.layer.cornerRadius = 5;
    self.titleInputBox.clipsToBounds = YES;
    
    [self.titleInputBox.layer setBorderColor:[[[UIColor grayColor] colorWithAlphaComponent:0.5] CGColor]];
    [self.titleInputBox.layer setBorderWidth:2.0];
    
    if (!self.collection) { 
        self.titleInputBox.text = @"";
    } else {
        self.titleInputBox.text = self.collection.name;
    }
    
}

- (void)setupDescriptionInputBox
{
    self.descriptionInputBox.layer.cornerRadius = 5;
    self.descriptionInputBox.clipsToBounds = YES;
    
    [self.descriptionInputBox.layer setBorderColor:[[[UIColor grayColor] colorWithAlphaComponent:0.5] CGColor]];
    [self.descriptionInputBox.layer setBorderWidth:2.0];
    
    if (!self.collection) { 
        self.descriptionInputBox.text = @"";
    } else {
        self.descriptionInputBox.text = self.collection.desc;
    }

}

//method to move the view up/down whenever the keyboard is shown/dismissed
-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5]; // if you want to slide up the view
    
    CGRect rect = self.contentView.frame;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        if (movedUp)
        {
            // 1. move the view's origin up so that the text field that will be hidden come above the keyboard 
            // 2. increase the size of the view so that the area behind the keyboard is covered up.
            rect.origin.y -= kOFFSET_FOR_KEYBOARD_PORTRAIT;
            rect.size.height += kOFFSET_FOR_KEYBOARD_PORTRAIT;
            self.viewIsMovedUp = YES;
        }
        else
        {
            // revert back to the normal state.
            rect.origin.y += kOFFSET_FOR_KEYBOARD_PORTRAIT;
            rect.size.height -= kOFFSET_FOR_KEYBOARD_PORTRAIT;
            self.viewIsMovedUp = NO;
        }
    } else {
        if (movedUp)
        {
            // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
            // 2. increase the size of the view so that the area behind the keyboard is covered up.
            rect.origin.y -= kOFFSET_FOR_KEYBOARD_LANDSCAPE;
            rect.size.height += kOFFSET_FOR_KEYBOARD_LANDSCAPE;
            self.viewIsMovedUp = YES;
        }
        else
        {
            // revert back to the normal state.
            rect.origin.y += kOFFSET_FOR_KEYBOARD_LANDSCAPE;
            rect.size.height -= kOFFSET_FOR_KEYBOARD_LANDSCAPE;
            self.viewIsMovedUp = NO;
        }
    }
    self.contentView.frame = rect;
    
    [UIView commitAnimations];
}

-(void)addSwipeGestureRecognizer
{
    UISwipeGestureRecognizer *rightSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                                      action:@selector(handleSwipeFrom:)];
    rightSwiper.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwiper];
    
    UISwipeGestureRecognizer *downSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                                      action:@selector(handleSwipeFrom:)];
    downSwiper.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:downSwiper];
}

-(void)showHelp
{
    if (self.collection) {
        [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_COLLECTION_DETAIL_EDIT", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES forceLandscape:UIInterfaceOrientationIsLandscape(self.interfaceOrientation)];
    } else {
        [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_COLLECTION_DETAIL_CREATE", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES forceLandscape:UIInterfaceOrientationIsLandscape(self.interfaceOrientation)];
    }
    
}

#pragma mark - Target / Action

- (IBAction)finishButtonPressed:(id)sender 
{
    NSString *cleanTitle = [self.titleInputBox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *cleanDesc = [self.descriptionInputBox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([cleanTitle length]) {
        Collection *oldCollection = self.collection;
        
        if (oldCollection) {
            if ([oldCollection.name isEqualToString:cleanTitle]) {
                oldCollection.desc = cleanDesc;
                self.importantChanges = YES;
                [self.delegate collectionDetailViewController:self finishedEditingCollection:oldCollection];
            } else {
                Collection *newCollection = [[DictVocTrainer instance] readCollectionWithName:cleanTitle];
                if (!newCollection) {
                    oldCollection.name = cleanTitle;
                    oldCollection.desc = cleanDesc;
                    self.importantChanges = YES;
                    [self.delegate collectionDetailViewController:self finishedEditingCollection:oldCollection];
                } else {
                    self.errorMessageLabel.text = NSLocalizedString(@"TITLE_NAME_GIVEN", nil);
                    [self.titleInputBox.layer setBorderColor:[[[UIColor redColor] colorWithAlphaComponent:0.5] CGColor]];
                }
            }
        } else {
            Collection *newCollection = [[DictVocTrainer instance] readCollectionWithName:cleanTitle];
            if (!newCollection) {
                newCollection = [[DictVocTrainer instance] collectionWithName:cleanTitle];
                newCollection.desc = cleanDesc;
                self.importantChanges = YES;
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:DVT_COLLECTION_NOTIFICATION_INSERTED object:self.collection]];
                [self.delegate collectionDetailViewController:self finishedCreatingCollection:newCollection];
            } else {
                self.errorMessageLabel.text = NSLocalizedString(@"TITLE_NAME_GIVEN", nil);
                [self.titleInputBox.layer setBorderColor:[[[UIColor redColor] colorWithAlphaComponent:0.5] CGColor]];
            }
        }
    } else {
        self.errorMessageLabel.text = NSLocalizedString(@"TITLE_NOT_EMPTY", nil);
        [self.titleInputBox.layer setBorderColor:[[[UIColor redColor] colorWithAlphaComponent:0.5] CGColor]];
    }
}


- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender 
{
    [self.delegate collectionDetailViewControllerGotCanceled:self];
}


- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.direction == UISwipeGestureRecognizerDirectionRight || recognizer.direction == UISwipeGestureRecognizerDirectionDown) {
        [self cancelButtonPressed:nil];;
    } 
}

#pragma mark - UITextView Delegate

//if the user pressed "done" it will resign, so the user cannot add enters into the text
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range 
 replacementText:(NSString *)text
{
    self.errorMessageLabel.text = @"";
    [self.titleInputBox.layer setBorderColor:[[[UIColor grayColor] colorWithAlphaComponent:0.5] CGColor]];
    
    //return if done pressed
    if ([text isEqualToString:@"\n"]) {
        
        [textView resignFirstResponder];
        
        if (self.viewIsMovedUp) {
            [self setViewMovedUp:NO];
        }
        
        
//        if ([textView isEqual:self.descriptionInputBox]) {
//            if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
//                if ([UIScreen mainScreen].bounds.size.height < 568) {
//                    [self setViewMovedUp:NO];
//                }
//            } else {
//                [self setViewMovedUp:NO];
//            }
//        }
        
        return FALSE;
    
    //keep within defined length
    } else {
        NSUInteger newLength = [textView.text length] + [text length] - range.length;
        if ([textView isEqual:self.titleInputBox]) {
            if (newLength > DVT_MAX_COLLECTION_NAME_LENGTH) {
                if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
                    [FWToastView toastInView:self.view.superview withText:[NSString stringWithFormat:@"%@ %i %@.", NSLocalizedString(@"TITLE_TOO_LONG_P1", nil), DVT_MAX_COLLECTION_NAME_LENGTH, NSLocalizedString(@"TITLE_TOO_LONG_P2", nil)] icon:FWToastViewIconWarning duration:FWToastViewDurationDefault withCloseButton:YES];
                }
                return NO;
            }
        } else if ([textView isEqual:self.descriptionInputBox]) {
            if (newLength > DVT_MAX_COLLECTION_DESC_LENGTH) {
                if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
                    [FWToastView toastInView:self.view.superview withText:[NSString stringWithFormat:@"%@ %i %@.", NSLocalizedString(@"DESC_TOO_LONG_P1", nil), DVT_MAX_COLLECTION_DESC_LENGTH, NSLocalizedString(@"DESC_TOO_LONG_P2", nil)] icon:FWToastViewIconWarning duration:FWToastViewDurationDefault withCloseButton:YES];
                }
                return NO;
            }
        }
    }
                    
    return TRUE;
}

#pragma mark - Notifications

- (void)keyboardWillShow:(NSNotification *)notif
{
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        if ([UIScreen mainScreen].bounds.size.height < 568) {
            if ([self.descriptionInputBox isFirstResponder] && self.contentView.frame.origin.y >= 0)
            {
                [self setViewMovedUp:YES];
            }
            else if (![self.descriptionInputBox isFirstResponder] && self.contentView.frame.origin.y < 0)
            {
                [self setViewMovedUp:NO];
            }
        }
    } else {
        if ([self.descriptionInputBox isFirstResponder] && self.contentView.frame.origin.y >= 0)
        {
            [self setViewMovedUp:YES];
        }
        else if (![self.descriptionInputBox isFirstResponder] && self.contentView.frame.origin.y < 0)
        {
            [self setViewMovedUp:NO];
        }

    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addSwipeGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(self.collection) {
        self.bottomBarTitleButton.title = NSLocalizedString(@"EDIT_COLLECTION", nil);
    }
    
    [self setupTitleInputBox];
    [self setupDescriptionInputBox];
    
    [self layoutViews];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
                                                 name:UIKeyboardWillShowNotification object:self.view.window];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    
    [self.delegate collectionDetailViewController:self willDisappearWithImportantChanges:self.importantChanges];
}

- (void)viewDidUnload
{
    [self setDescriptionInputBox:nil];
    [self setTitleInputBox:nil];
    [self setErrorMessageLabel:nil];
    [self setBottomBarTitleButton:nil];
    [self setCancelButton:nil];
    [self setFinishButton:nil];
    [self setTitleLabel:nil];
    [self setDescriptionLabel:nil];
    [self setContentView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
