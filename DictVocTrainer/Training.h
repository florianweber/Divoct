//
//  TrainingSettings.h
//  Divoct
//
//  Created by Florian Weber on 03.08.12.
//  Copyright (c) 2012 IBM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Collection.h"
#import "TrainingResult.h"
#import "GlobalDefinitions.h"

@interface Training : NSObject

@property (nonatomic, strong) NSSet *collections;
@property (nonatomic, strong) NSMutableSet *exercises;
@property (nonatomic, strong) NSString *title;

@property (nonatomic) TrainingAnswerInputMode trainingAnswerInputMode;
@property (nonatomic) TrainingWrongAnswerHandlingMode trainingWrongAnswerHandlingMode;

@property (nonatomic, strong) TrainingResult *trainingResult;
@property (nonatomic, strong) NSManagedObjectID *trainingResultsObjectId;

-(int)totalExerciseCountAvailable;
-(int)totalExerciseCountAvailableWithoutDuplicates;

@end
