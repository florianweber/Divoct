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

@property (nonatomic, strong) Collection *collection;
@property (nonatomic, strong) NSMutableArray *exercises;
@property (nonatomic, strong) NSString *title;

@property (nonatomic) TrainingAnswerInputMode trainingAnswerInputMode;
@property (nonatomic) TrainingCode trainingCode;

@property (nonatomic, strong) TrainingResult *trainingResult;
@property (nonatomic, strong) NSManagedObjectID *trainingResultsObjectId;

@end
