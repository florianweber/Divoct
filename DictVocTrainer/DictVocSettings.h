//
//  DictVocSettings.h
//  Divoct
//
//  Created by Florian Weber on 18.10.12.
//  Copyright (c) 2012 IBM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DictVocSettings : NSObject

@property (nonatomic) int searchMode;
@property (nonatomic) int trainingAnswerInputMode;
@property (nonatomic) int trainingWrongAnswerHandling;
@property (nonatomic) BOOL trainingWarnWellKnownOnly;
@property (nonatomic) int trainingPerfectSuccessRate;
@property (nonatomic) BOOL trainingTextInputAutoCorrection;


+(DictVocSettings *)instance;


@end
