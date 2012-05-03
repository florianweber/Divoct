/*
 FWToastView.h
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

#import <Foundation/Foundation.h>

#define FWToastViewDefaultTriangleHeight 30
#define FWToastViewDefaultTriangleWidth 30

typedef enum {
    FWToastViewDurationDefault = 2,
    FWToastViewDurationUnlimited = 0
} FWToastViewDuration;

typedef enum {
    FWToastViewIconNone = 0,
    FWToastViewIconInfo = 1,
    FWToastViewIconWarning = 2,
    FWToastViewIconAlert = 3
} FWToastViewIcon;

typedef enum {
    FWToastViewPointingFromDirectionNone = 0,
    FWToastViewPointingFromDirectionBottom = 1,
    FWToastViewPointingFromDirectionTop = 2,
    FWToastViewPointingFromDirectionLeft = 3,
    FWToastViewPointingFromDirectionRight = 4
} FWToastViewPointingFromDirection;

@interface FWToastView : UIView

- (id)initWithText:(NSString *)text parentView:(UIView *)parentView icon:(FWToastViewIcon)icon duration:(CGFloat)seconds withCloseButton:(BOOL)withCloseButton pointingToView:(UIView *)pointToView fromDirection:(FWToastViewPointingFromDirection)direction triangleViewWidth:(int)triangleViewWidth triangleViewHeight:(int)triangleViewHeight;

+(void)toastInView:(UIView *)parentView withText:(NSString *)text;
+(void)toastInView:(UIView *)parentView withText:(NSString *)text icon:(FWToastViewIcon)icon;
+(void)toastInView:(UIView *)parentView withText:(NSString *)text icon:(FWToastViewIcon)icon duration:(CGFloat)seconds;
+(void)toastInView:(UIView *)parentView withText:(NSString *)text icon:(FWToastViewIcon)icon duration:(CGFloat)seconds withCloseButton:(BOOL)closeButton;
+(void)toastInView:(UIView *)parentView withText:(NSString *)text icon:(FWToastViewIcon)icon duration:(float)seconds withCloseButton:(BOOL)closeButton pointingToView:(UIView *)pointToView fromDirection:(FWToastViewPointingFromDirection)direction;

+(void)parallelMultiToast:(NSArray *)someToastViews; //needs an array of FWToastViews, here is an example:

/*
 NSMutableArray *toastArray = [[NSMutableArray alloc] init];
 FWToastView *firstToast = [[FWToastView alloc] initWithText:@"Test" parentView:self.view icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES pointingToView:self.editTranslationsButton fromDirection:FWToastViewPointingFromDirectionBottom];
 [toastArray addObject:firstToast];
 
 FWToastView *secondToast = [[FWToastView alloc] initWithText:@"Test2" parentView:self.view icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES pointingToView:self.searchWikipediaButton fromDirection:FWToastViewPointingFromDirectionTop];
 [toastArray addObject:secondToast];
 
 [FWToastView parallelMultiToast:toastArray];
 */

@end
