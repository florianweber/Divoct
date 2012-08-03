//
//  TrainingSettings.m
//  Divoct
//
//  Created by Florian Weber on 03.08.12.
//  Copyright (c) 2012 IBM. All rights reserved.
//

#import "Training.h"

@implementation Training

@synthesize collection = _collection;
@synthesize exercises = _exercises;
@synthesize title = _title;

@synthesize trainingAnswerInputMode = _trainingAnswerInputMode;
@synthesize trainingCode = _trainingCode;

@synthesize trainingResult = _trainingResult;
@synthesize trainingResultsObjectId = _trainingResultsObjectId;


-(void)setCollection:(Collection *)collection
{
    _collection = collection;
    
    //set training title
    if ([self.collection.name isEqualToString:NSLocalizedString(@"RECENTS_TITLE", nil)]) {
        self.title = [NSLocalizedString(@"RECENTS_DISPLAY_TITLE", nil) stringByAppendingFormat:@" - %@", NSLocalizedString(@"TRAINING", nil)];
    } else {
        self.title = [self.collection.name stringByAppendingFormat:@" - %@", NSLocalizedString(@"TRAINING", nil)];
    }
}

@end
