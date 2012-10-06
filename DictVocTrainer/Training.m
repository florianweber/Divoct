//
//  TrainingSettings.m
//  Divoct
//
//  Created by Florian Weber on 03.08.12.
//  Copyright (c) 2012 IBM. All rights reserved.
//

#import "Training.h"

@implementation Training

@synthesize collections = _collections;
@synthesize exercises = _exercises;
@synthesize title = _title;

@synthesize trainingAnswerInputMode = _trainingAnswerInputMode;
@synthesize trainingWrongAnswerHandlingMode = _trainingWrongAnswerHandlingMode;
@synthesize trainingCode = _trainingCode;

@synthesize trainingResult = _trainingResult;
@synthesize trainingResultsObjectId = _trainingResultsObjectId;


-(void)setCollections:(NSMutableArray *)collections
{
    _collections = collections;
    
    //set training title
    self.title = @"";
    for (int i=0; i<collections.count; i++) {
        if (i>0) {
            self.title = [self.title stringByAppendingString:@", "];
        }
        if ([((Collection *)collections[i]).name isEqualToString:NSLocalizedString(@"RECENTS_TITLE", nil)]) {
            self.title = [self.title stringByAppendingString:NSLocalizedString(@"RECENTS_DISPLAY_TITLE", nil)];
        } else {
            self.title = [self.title stringByAppendingString:((Collection *)collections[i]).name];
        }
    }
}

-(int)totalExerciseCountAvailable
{
    int totalCount = 0;
    for (Collection *collection in self.collections) {
        totalCount += collection.exercises.count;
    }
    return totalCount;
}

@end
