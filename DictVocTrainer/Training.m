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

@synthesize trainingResult = _trainingResult;
@synthesize trainingResultsObjectId = _trainingResultsObjectId;


-(void)setCollections:(NSMutableSet *)collections
{
    _collections = collections;
    
    //set training title
    self.title = @"";
    
    NSEnumerator *collectionsEnumerator = [collections objectEnumerator];
    Collection *collection;
    
    BOOL addComma = NO;
    while ((collection = [collectionsEnumerator nextObject])) {
        if (addComma) {
            self.title = [self.title stringByAppendingString:@", "];
        }
        if ([collection.name isEqualToString:NSLocalizedString(@"RECENTS_TITLE", nil)]) {
            self.title = [self.title stringByAppendingString:NSLocalizedString(@"RECENTS_DISPLAY_TITLE", nil)];
        } else {
            self.title = [self.title stringByAppendingString:collection.name];
        }
        addComma = YES;
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

-(int)totalExerciseCountAvailableWithoutDuplicates
{
    NSMutableSet *allExercisesWoDuplicates = [NSMutableSet set];
    for (Collection *collection in self.collections) {
        [allExercisesWoDuplicates addObjectsFromArray:collection.exercises.array];
    }
    return allExercisesWoDuplicates.count;
}

@end
