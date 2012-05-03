/*
LoadingViewController.m
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


#import "LoadingViewController.h"
#import "FWToastView.h"

@interface LoadingViewController()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextView *infoMessageView;


@end

@implementation LoadingViewController
@synthesize activityIndicator = _activityIndicator;
@synthesize textView = _textView;
@synthesize text = _text;
@synthesize infoText = _infoText;
@synthesize infoMessageView = _infoMessageView;
@synthesize delegate;

- (void)setText:(NSString *)text
{
    _text = text;
    self.textView.text = text;
}

- (NSString*)infoText 
{
    if (!_infoText) {
        _infoText = NSLocalizedString(@"SETUP_INFO", nil);
    }
    return _infoText;
}

- (void)setInfoText:(NSString *)infoText
{
    _infoText = infoText;
    self.infoMessageView.text = infoText;
}

- (void)startAnimating
{
    [self.activityIndicator startAnimating];
}

- (void)stopAnimating
{
    [self.activityIndicator stopAnimating];
}

- (void)dismiss
{
    [self stopAnimating];
    [self.presentingViewController dismissModalViewControllerAnimated:YES];
}

-(void)showHelp
{
    [FWToastView toastInView:self.view withText:NSLocalizedString(@"HELP_LOADINGVIEW", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.textView.text = self.text;
    self.infoMessageView.text = self.infoText;
}

- (void)viewDidUnload {
    [self setActivityIndicator:nil];
    [self setTextView:nil];
    [super viewDidUnload];
}
@end
