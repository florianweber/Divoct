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

#define kOFFSET_FOR_KEYBOARD 80.0

@interface CollectionDetailViewController () <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *titleInputBox;
@property (weak, nonatomic) IBOutlet UITextView *descriptionInputBox;
@property (weak, nonatomic) IBOutlet UILabel *errorMessageLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *bottomBarTitleButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *finishButton;

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

#pragma mark - My Messages

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
    
    CGRect rect = self.view.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard 
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y -= kOFFSET_FOR_KEYBOARD;
        rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y += kOFFSET_FOR_KEYBOARD;
        rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.view.frame = rect;
    
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
        [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_COLLECTION_DETAIL_EDIT", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
    } else {
        [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_COLLECTION_DETAIL_CREATE", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
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
        if ([textView isEqual:self.descriptionInputBox]) {
            [self setViewMovedUp:NO];
        }
        
        return FALSE;
    
    //keep within defined length
    } else {
        NSUInteger newLength = [textView.text length] + [text length] - range.length;
        if ([textView isEqual:self.titleInputBox]) {
            if (newLength > DVT_MAX_COLLECTION_NAME_LENGTH) {
                [FWToastView toastInView:self.view.superview withText:[NSString stringWithFormat:@"%@ %i %@.", NSLocalizedString(@"TITLE_TOO_LONG_P1", nil), DVT_MAX_COLLECTION_NAME_LENGTH, NSLocalizedString(@"TITLE_TOO_LONG_P2", nil)] icon:FWToastViewIconWarning duration:FWToastViewDurationDefault withCloseButton:YES];
                return NO;
            }
        } else if ([textView isEqual:self.descriptionInputBox]) {
            if (newLength > DVT_MAX_COLLECTION_DESC_LENGTH) {
                [FWToastView toastInView:self.view.superview withText:[NSString stringWithFormat:@"%@ %i %@.", NSLocalizedString(@"DESC_TOO_LONG_P1", nil), DVT_MAX_COLLECTION_DESC_LENGTH, NSLocalizedString(@"DESC_TOO_LONG_P2", nil)] icon:FWToastViewIconWarning duration:FWToastViewDurationDefault withCloseButton:YES];
                return NO;
            }
        }
    }
                    
    return TRUE;
}

#pragma mark - Notifications

- (void)keyboardWillShow:(NSNotification *)notif
{
    if ([self.descriptionInputBox isFirstResponder] && self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (![self.descriptionInputBox isFirstResponder] && self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
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
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
