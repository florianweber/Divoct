/*
 FWToastView.m
 Divoct
 
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
#import "FWToastView.h"
#import "TriangleView.h"


// Set visibility duration
static const CGFloat kDuration = 2;


// Static toastview queue variable
static NSMutableArray *toasts;


@interface FWToastView ()


@property (nonatomic, strong) TriangleView *triangleView;
@property (nonatomic, weak) UIView *parentView;
@property (nonatomic, strong) UIView *messageView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic) CGFloat duration;

- (void)fadeToastOut;
+ (void)nextToastInView:(UIView *)parentView;

@end


@implementation FWToastView

@synthesize triangleView = _triangleView;
@synthesize messageView = _messageView;
@synthesize textLabel = _textLabel;
@synthesize iconImageView = _iconImageView;
@synthesize closeButton = _closeButton;
@synthesize duration = _duration;
@synthesize parentView = _parentView;


#pragma mark - Init

- (id)initWithText:(NSString *)text parentView:(UIView *)parentView icon:(FWToastViewIcon)icon duration:(CGFloat)seconds withCloseButton:(BOOL)withCloseButton pointingToView:(UIView *)pointToView fromDirection:(FWToastViewPointingFromDirection)direction triangleViewWidth:(int)triangleViewWidth triangleViewHeight:(int)triangleViewHeight {
	if ((self = [self initWithFrame:CGRectZero])) {
        
        //-- configure items ------------------------------------------------------------------------------------------------
        //set parent view
        self.parentView = parentView;
        
        //configure main view
        self.backgroundColor = [UIColor clearColor];
        
        //configure triangle (if necessary)
        if (pointToView) {
            self.triangleView = [[TriangleView alloc] initWithFrame:CGRectMake(0, 0, triangleViewWidth, triangleViewHeight)];
            self.triangleView.contentMode = UIViewContentModeRedraw;
            self.triangleView.backgroundColor = [UIColor clearColor];
            self.triangleView.direction = direction;
            [self addSubview:self.triangleView];
        }
        
		//configure message view
        self.messageView = [[UIView alloc] initWithFrame:CGRectZero];
		self.messageView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.7];
		self.messageView.layer.cornerRadius = 5;
		self.messageView.autoresizingMask = UIViewAutoresizingNone;
		self.messageView.autoresizesSubviews = NO;
        self.messageView.contentMode = UIViewContentModeCenter;
        self.messageView.layer.shouldRasterize = NO;
        [self.messageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fadeToastOut)]];
        [self addSubview:self.messageView];
		
        //configure icon todo
        UIImage *iconImage = nil;
        if (icon == FWToastViewIconInfo) {
            iconImage = [UIImage imageNamed:@"infoIcon.png"];
        } else if (icon == FWToastViewIconWarning) {
            iconImage = [UIImage imageNamed:@"warningIcon.png"];
        } else if (icon == FWToastViewIconAlert) {
            iconImage = [UIImage imageNamed:@"errorIcon.png"];
        }
        
        if (iconImage) {
            self.iconImageView = [[UIImageView alloc] initWithImage:iconImage];
            [self.messageView addSubview:self.iconImageView];
        }
        
		//configure label
		self.textLabel = [[UILabel alloc] init];
		self.textLabel.text = text;
		self.textLabel.font = [UIFont systemFontOfSize:14];
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = UILineBreakModeWordWrap;
		self.textLabel.textColor = [UIColor whiteColor];
		self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.layer.shouldRasterize = NO;
        [self.messageView addSubview:self.textLabel];
        
        //configure close button todo
        if (withCloseButton) {
            UIButton *closeButton = [[UIButton alloc] init];
            [closeButton addTarget:self action:@selector(fadeToastOut) forControlEvents:UIControlEventTouchUpInside];
            [closeButton setImage:[UIImage imageNamed:@"closeButton2_pressed.png"] forState:UIControlStateSelected];
            [closeButton setImage:[UIImage imageNamed:@"closeButton2_normal.png"] forState:UIControlStateNormal];            
            CGRect closeButtonFrame = CGRectMake(0, 0, 24, 24);
            closeButton.frame = closeButtonFrame;
            self.closeButton = closeButton;
            [self.messageView addSubview:closeButton];
        }
        
        //set duration
        self.duration = seconds;
        
        
        //-- Configure Layout ------------------------------------------------------------------------------------------
        
        //-- pointToView -----------------------------------------------------------------------------------------------
        //coordinates for pointToView
        int xStartPosition = 0;
        int yStartPosition = 0;
        
        //todo: this currently calculates the position of triangleView in parentview, not in self!! (must use it and then convert it back later)
        //size and position point to view
        if (pointToView) {
            CGRect positionOfPointToViewInParentView = [pointToView convertRect:pointToView.bounds toView:parentView];
            
            int peakX = 0;
            int peakY = 0;
            
            if (direction == FWToastViewPointingFromDirectionBottom) {
                peakX = positionOfPointToViewInParentView.origin.x + (positionOfPointToViewInParentView.size.width / 2);
                peakY = positionOfPointToViewInParentView.origin.y + positionOfPointToViewInParentView.size.height;
                xStartPosition = peakX - (self.triangleView.frame.size.width / 2);
                yStartPosition = peakY;
            } else if (direction == FWToastViewPointingFromDirectionTop) {
                peakX = positionOfPointToViewInParentView.origin.x + (positionOfPointToViewInParentView.size.width / 2);
                peakY = positionOfPointToViewInParentView.origin.y;
                xStartPosition = peakX - (self.triangleView.frame.size.width / 2);
                yStartPosition = peakY - self.triangleView.frame.size.height;
            } else if (direction == FWToastViewPointingFromDirectionLeft) {
                peakX = positionOfPointToViewInParentView.origin.x;
                peakY = positionOfPointToViewInParentView.origin.y + (positionOfPointToViewInParentView.size.height / 2);
                xStartPosition = peakX - self.triangleView.frame.size.width;
                yStartPosition = peakY - (self.triangleView.frame.size.height / 2);
            } else if (direction == FWToastViewPointingFromDirectionRight) {
                peakX = positionOfPointToViewInParentView.origin.x + positionOfPointToViewInParentView.size.width;
                peakY = positionOfPointToViewInParentView.origin.y + (positionOfPointToViewInParentView.size.height / 2);
                xStartPosition = peakX;
                yStartPosition = peakY - (self.triangleView.frame.size.height / 2);
            }
            
            CGRect triangeViewFrame = self.triangleView.frame;
            triangeViewFrame.origin.x = xStartPosition;
            triangeViewFrame.origin.y = yStartPosition;
            self.triangleView.frame = triangeViewFrame;
        }
        
        //-- messageView -----------------------------------------------------------------------------------------------
        //reset coordinates for message view contents
        xStartPosition = 10;
        yStartPosition = 6;
        int xMax = 0;
        int yMax = 0;
        
        //size and position icon
        if (self.iconImageView) {
            self.iconImageView.frame = CGRectOffset(self.iconImageView.frame, xStartPosition, yStartPosition);
            xStartPosition += self.iconImageView.frame.size.width + 7;
            yStartPosition = 10;
            xMax = MAX(xMax, self.iconImageView.frame.origin.x + self.iconImageView.frame.size.width);
            yMax = MAX(yMax, self.iconImageView.frame.origin.y + self.iconImageView.frame.size.height);
        }
        
        //size and position label
        int pointToViewWidthReduce = 0;
        int pointToViewHeightReduce = 0;
        if (pointToView) {
            CGRect positionOfPointToViewInParentView = [pointToView convertRect:pointToView.bounds toView:parentView];
            
            if (direction == FWToastViewPointingFromDirectionLeft) {
                pointToViewWidthReduce = self.triangleView.frame.size.width + positionOfPointToViewInParentView.size.width + (parentView.frame.size.width - positionOfPointToViewInParentView.origin.x);
            } else if (direction == FWToastViewPointingFromDirectionRight) {
                pointToViewWidthReduce = self.triangleView.frame.size.width + positionOfPointToViewInParentView.origin.x + positionOfPointToViewInParentView.size.width;
            } else if (direction == FWToastViewPointingFromDirectionTop) {
                pointToViewHeightReduce = self.triangleView.frame.size.height + positionOfPointToViewInParentView.size.height + (parentView.frame.size.height - positionOfPointToViewInParentView.origin.y);
            } else if (direction == FWToastViewPointingFromDirectionBottom) {
                pointToViewHeightReduce = self.triangleView.frame.size.height + positionOfPointToViewInParentView.size.height + positionOfPointToViewInParentView.origin.y;
            }
        }
        
        int textMaxWidth = parentView.frame.size.width - xStartPosition - (self.closeButton ? (self.closeButton.frame.size.width + 7) : 0) - 10 - pointToViewWidthReduce - 10;
        int textMaxHeight = parentView.frame.size.height - pointToViewHeightReduce;
        
        self.textLabel.frame = CGRectOffset(self.textLabel.frame, xStartPosition, yStartPosition);
        CGRect textLabelFrame = self.textLabel.frame;
        textLabelFrame.size = [self.textLabel.text sizeWithFont:self.textLabel.font constrainedToSize:CGSizeMake(textMaxWidth, textMaxHeight) lineBreakMode:UILineBreakModeWordWrap];
        self.textLabel.frame = textLabelFrame;
        
        xStartPosition += textLabelFrame.size.width + 7;
        xMax = MAX(xMax, self.textLabel.frame.origin.x + self.textLabel.frame.size.width);
        yMax = MAX(yMax, self.textLabel.frame.origin.y + self.textLabel.frame.size.height);
        
        //reposition icon
        if (self.iconImageView) {
            CGRect imageViewFrame = self.iconImageView.frame;
            imageViewFrame.origin.y = self.textLabel.frame.origin.y + (self.textLabel.frame.size.height / 2) - (imageViewFrame.size.height / 2);
            self.iconImageView.frame = imageViewFrame;
        }
        
        //size and position close Button
        if (self.closeButton) {
            CGRect closeButtonFrame = self.closeButton.frame;
            closeButtonFrame.origin = CGPointMake(xStartPosition, self.textLabel.frame.origin.y + (self.textLabel.frame.size.height / 2) - (closeButtonFrame.size.height / 2));
            self.closeButton.frame = closeButtonFrame;
            
            xMax = MAX(xMax, self.closeButton.frame.origin.x + self.closeButton.frame.size.width);
            yMax = MAX(yMax, self.closeButton.frame.origin.y + self.closeButton.frame.size.height);
        } 
        
        
        
        //add space at bottom and right
        if ((xMax % 2) == 1) {
            xMax += 9;
        } else {
            xMax += 10;
        }
        yMax += 10;
        
        //size and position message view frame
        self.messageView.frame = CGRectMake(0, 0, xMax, yMax);
        
        
        //-- main View -----------------------------------------------------------------------------------------------
        //size and position own frame
        self.frame = CGRectMake(parentView.center.x - (xMax / 2), parentView.center.y - (yMax / 2), xMax, yMax);
        self.frame = CGRectIntegral(self.frame);
        self.alpha = 0.0f;
        
        //if pointing to view
        if (pointToView) {
            if (direction == FWToastViewPointingFromDirectionBottom) {
                self.frame = CGRectMake(self.frame.origin.x, self.triangleView.frame.origin.y, self.frame.size.width, self.frame.size.height + self.triangleView.frame.size.height);
                self.triangleView.frame = CGRectMake(self.triangleView.frame.origin.x - self.frame.origin.x, 0, self.triangleView.frame.size.width, self.triangleView.frame.size.height);
                
                int messageViewXStart = ((self.triangleView.frame.origin.x - 5) < self.messageView.frame.origin.x) ? self.triangleView.frame.origin.x - 5 : self.messageView.frame.origin.x;
                self.messageView.frame = CGRectMake(messageViewXStart, self.triangleView.frame.size.height, self.messageView.frame.size.width, self.messageView.frame.size.height);
            } else if (direction == FWToastViewPointingFromDirectionTop) {
                self.frame = CGRectMake(self.frame.origin.x, self.triangleView.frame.origin.y - self.messageView.frame.size.height, self.frame.size.width, self.frame.size.height + self.triangleView.frame.size.height);
                self.triangleView.frame = CGRectMake(self.triangleView.frame.origin.x - self.frame.origin.x, self.messageView.frame.origin.y + self.messageView.frame.size.height, self.triangleView.frame.size.width, self.triangleView.frame.size.height);
                int messageViewXStart = ((self.triangleView.frame.origin.x - 5) < self.messageView.frame.origin.x) ? self.triangleView.frame.origin.x - 5 : self.messageView.frame.origin.x;
                self.messageView.frame = CGRectMake(messageViewXStart, self.messageView.frame.origin.y, self.messageView.frame.size.width, self.messageView.frame.size.height);
            } else if (direction == FWToastViewPointingFromDirectionLeft) {
                self.frame = CGRectMake(self.triangleView.frame.origin.x - self.messageView.frame.size.width, (self.triangleView.frame.origin.y + (self.triangleView.frame.size.height / 2)) - (self.messageView.frame.size.height / 2), self.triangleView.frame.size.width + self.messageView.frame.size.width, self.messageView.frame.size.height);
                self.triangleView.frame = CGRectMake(self.messageView.frame.size.width, (self.messageView.frame.size.height / 2) - (self.triangleView.frame.size.height / 2), self.triangleView.frame.size.width, self.triangleView.frame.size.height);
            } else if (direction == FWToastViewPointingFromDirectionRight) {
                self.frame = CGRectMake(self.triangleView.frame.origin.x, (self.triangleView.frame.origin.y + (self.triangleView.frame.size.height / 2)) - (self.messageView.frame.size.height / 2), self.triangleView.frame.size.width + self.messageView.frame.size.width, self.messageView.frame.size.height);
                self.triangleView.frame = CGRectMake(0, (self.messageView.frame.size.height / 2) - (self.triangleView.frame.size.height / 2), self.triangleView.frame.size.width, self.triangleView.frame.size.height);
                self.messageView.frame = CGRectMake(self.triangleView.frame.size.width, 0, self.messageView.frame.size.width + self.triangleView.frame.size.width, self.messageView.frame.size.height);
            }
        }
	}
	
	return self;
}


#pragma mark - My Messages

+ (void)toastInView:(UIView *)parentView withText:(NSString *)text 
{
	[FWToastView toastInView:parentView withText:text icon:FWToastViewIconNone duration:kDuration withCloseButton:NO pointingToView:nil fromDirection:FWToastViewPointingFromDirectionNone];
}

+(void)toastInView:(UIView *)parentView withText:(NSString *)text icon:(FWToastViewIcon)icon 
{
    [FWToastView toastInView:parentView withText:text icon:icon duration:kDuration withCloseButton:NO pointingToView:nil fromDirection:FWToastViewPointingFromDirectionNone];
}

+(void)toastInView:(UIView *)parentView withText:(NSString *)text icon:(FWToastViewIcon)icon duration:(CGFloat)seconds 
{
    [FWToastView toastInView:parentView withText:text icon:icon duration:seconds withCloseButton:NO pointingToView:nil fromDirection:FWToastViewPointingFromDirectionNone];
}

+(void)toastInView:(UIView *)parentView withText:(NSString *)text icon:(FWToastViewIcon)icon duration:(CGFloat)seconds withCloseButton:(BOOL)closeButton 
{
    [FWToastView toastInView:parentView withText:text icon:icon duration:seconds withCloseButton:closeButton pointingToView:nil fromDirection:FWToastViewPointingFromDirectionNone];
}

+(void)toastInView:(UIView *)parentView withText:(NSString *)text icon:(FWToastViewIcon)icon duration:(CGFloat)seconds withCloseButton:(BOOL)withCloseButton pointingToView:(UIView *)pointToView fromDirection:(FWToastViewPointingFromDirection)direction
{
    //don't add the same toast multiple times
    if ([toasts count]) {
        FWToastView *lastToastView = [toasts lastObject];
        if ([lastToastView.textLabel.text isEqualToString:text]) {
            return;
        }
    }
    
    int triangleViewWidth = FWToastViewDefaultTriangleWidth;
    int triangleViewHeight = FWToastViewDefaultTriangleHeight;
    if (direction == FWToastViewPointingFromDirectionLeft || direction == FWToastViewPointingFromDirectionRight) {
        triangleViewWidth = FWToastViewDefaultTriangleWidth - 10;
    } else {
        triangleViewHeight = FWToastViewDefaultTriangleHeight - 10;
    }
    
    FWToastView *view = [[FWToastView alloc] initWithText:text parentView:parentView icon:icon duration:seconds withCloseButton:withCloseButton pointingToView:pointToView fromDirection:direction triangleViewWidth:triangleViewWidth triangleViewHeight:triangleViewHeight];
    
    
    //add new instance to queue
	if (toasts == nil) {
		toasts = [[NSMutableArray alloc] initWithCapacity:1];
		[toasts addObject:view];
		[FWToastView nextToastInView:parentView];
	}
	else {
		[toasts addObject:view];
	}
}

- (void)showToast {
    // Fade in
    [self.parentView addSubview:self];
    [UIView animateWithDuration:.2  delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.alpha = 1.0;
    } completion:^(BOOL finished){
    }];
    
    // Fade out with timer
    if (self.duration > 0) {
        [self performSelector:@selector(fadeToastOut) withObject:nil afterDelay:self.duration];
    }
}


+(void)parallelMultiToast:(NSArray *)someToastViews {
    for (FWToastView *toast in someToastViews) {
        [toast showToast];
    }
}


- (void)fadeToastOut {
	// Fade in parent view
  [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
           self.alpha = 0.f;
       } completion:^(BOOL finished) {
           UIView *parentView = self.superview;
           [self removeFromSuperview];
         
           // Remove current view from array
           [toasts removeObject:self];
           if ([toasts count] == 0) {
               toasts = nil;
           } else {
               [FWToastView nextToastInView:parentView];
           }
   }];
}

+ (void)nextToastInView:(UIView *)parentView {
	if ([toasts count] > 0) {
        FWToastView *view = [toasts objectAtIndex:0];
        [view showToast];
    }
}

@end
