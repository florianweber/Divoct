//
//  DictVocSettings.m
//  Divoct
//
//  Created by Florian Weber on 18.10.12.
//  Copyright (c) 2012 IBM. All rights reserved.
//

#import "DictVocSettings.h"
#import "GlobalDefinitions.h"


@interface DictVocSettings()

@end

@implementation DictVocSettings

static DictVocSettings *singleton;
static NSUserDefaults *userDefaults;

@synthesize searchMode = _searchMode;
@synthesize trainingAnswerInputMode = _trainingAnswerInputMode;
@synthesize trainingWrongAnswerHandling = _trainingWrongAnswerHandling;
@synthesize trainingWarnWellKnownOnly = _trainingWarnWellKnownOnly;
@synthesize trainingPerfectSuccessRate = _trainingPerfectSuccessRate;
@synthesize trainingTextInputAutoCorrection = _trainingTextInputAutoCorrection;

#pragma mark - Initialization

+(void)initialize
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        singleton = [[DictVocSettings alloc] init];
        userDefaults = [NSUserDefaults standardUserDefaults];
    }
}

+(DictVocSettings *)instance
{
    return singleton;
}

#pragma mark - My messages


/*  **************
    Search Mode
 *  **************/
-(void)setSearchMode:(int)searchMode
{
    NSString *searchModeKey = DVT_NSUSERDEFAULTS_SEARCHMODE_KEY;
    [userDefaults setObject:[NSNumber numberWithInt:searchMode] forKey:searchModeKey];
    [userDefaults synchronize];
    NSNotification *searchCaseSwitchedNotification = [NSNotification notificationWithName:DVT_SETTINGS_NOTIFICATION_SEARCHCASESWITCHED object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:searchCaseSwitchedNotification];
    _searchMode = searchMode;
}

-(int)searchMode
{
    NSString *searchModeKey = DVT_NSUSERDEFAULTS_SEARCHMODE_KEY;
    NSNumber *userDefaultsSearchMode = (NSNumber *)[userDefaults objectForKey:searchModeKey];
    if (userDefaultsSearchMode) {
        _searchMode = userDefaultsSearchMode.intValue;
    } else {
        [userDefaults setObject:[NSNumber numberWithInt:DVT_DEFAULTSEARCHMODE] forKey:searchModeKey];
        [userDefaults synchronize];
        _searchMode = DVT_DEFAULTSEARCHMODE;
    }
    
    return _searchMode;
}

/*  **************
    Training Answer Input Mode
 *  **************/
-(void)setTrainingAnswerInputMode:(int)trainingAnswerInputMode
{
    NSString *trainingModeKey = DVT_NSUSERDEFAULTS_TRAININGMODE_KEY;
    [userDefaults setObject:[NSNumber numberWithInt:trainingAnswerInputMode] forKey:trainingModeKey];
    [userDefaults synchronize];
    _trainingAnswerInputMode = trainingAnswerInputMode;
}

-(int)trainingAnswerInputMode
{
    NSString *trainingModeKey = DVT_NSUSERDEFAULTS_TRAININGMODE_KEY;
    NSNumber *userDefaultsTrainingMode = (NSNumber *)[userDefaults objectForKey:trainingModeKey];
    if (userDefaultsTrainingMode) {
        _trainingAnswerInputMode = userDefaultsTrainingMode.intValue;
    } else {
        [userDefaults setObject:[NSNumber numberWithInt:DVT_DEFAULT_TRAINING_ANSWER_INPUT_MODE] forKey:trainingModeKey];
        [userDefaults synchronize];
        _trainingAnswerInputMode = DVT_DEFAULT_TRAINING_ANSWER_INPUT_MODE;
    }
    
    return _trainingAnswerInputMode;
}

/*  **************
    Wrong Answer Handling Mode
 *  **************/
-(void)setTrainingWrongAnswerHandling:(int)trainingWrongAnswerHandling
{
    NSString *wrongAnswerHandlingModeKey = DVT_NSUSERDEFAULTS_WRONGANSWERHANDLINGMODE_KEY;
    [userDefaults setObject:[NSNumber numberWithInt:trainingWrongAnswerHandling] forKey:wrongAnswerHandlingModeKey];
    [userDefaults synchronize];
    _trainingWrongAnswerHandling = trainingWrongAnswerHandling;
}

-(int)trainingWrongAnswerHandling
{
    NSString *wrongAnswerHandlingModeKey = DVT_NSUSERDEFAULTS_WRONGANSWERHANDLINGMODE_KEY;
    NSNumber *userDefaultsWrongAnswerHandlingMode = (NSNumber *)[userDefaults objectForKey:wrongAnswerHandlingModeKey];
    if (userDefaultsWrongAnswerHandlingMode) {
        _trainingWrongAnswerHandling = userDefaultsWrongAnswerHandlingMode.intValue;
    } else {
        [userDefaults setObject:[NSNumber numberWithInt:DVT_DEFAULT_TRAINING_WRONG_ANSWER_HANDLING_MODE] forKey:wrongAnswerHandlingModeKey];
        [userDefaults synchronize];
        _trainingWrongAnswerHandling = DVT_DEFAULT_TRAINING_WRONG_ANSWER_HANDLING_MODE;
    }
    
    return _trainingWrongAnswerHandling;
}

/*  **************
    Training Warn Well Known Words
 *  **************/
-(void)setTrainingWarnWellKnownOnly:(BOOL)trainingWarnWellKnownOnly
{
    NSString *warnWellKnownOnlyKey = DVT_NSUSERDEFAULTS_WARN_WELLKNOWN_ONLY_KEY;
    [userDefaults setObject:[NSNumber numberWithBool:trainingWarnWellKnownOnly] forKey:warnWellKnownOnlyKey];
    [userDefaults synchronize];
    _trainingWarnWellKnownOnly = trainingWarnWellKnownOnly;
}

-(BOOL)trainingWarnWellKnownOnly
{
    NSString *warnWellKnownOnlyKey = DVT_NSUSERDEFAULTS_WARN_WELLKNOWN_ONLY_KEY;
    NSNumber *userDefaultsWarnWellKnownOnly = (NSNumber *)[userDefaults objectForKey:warnWellKnownOnlyKey];
    if (userDefaultsWarnWellKnownOnly) {
        _trainingWarnWellKnownOnly = userDefaultsWarnWellKnownOnly.boolValue;
    } else {
        [userDefaults setObject:[NSNumber numberWithBool:DVT_DEFAULT_WARN_WELLKNOWN_ONLY] forKey:warnWellKnownOnlyKey];
        [userDefaults synchronize];
        _trainingWarnWellKnownOnly = DVT_DEFAULT_WARN_WELLKNOWN_ONLY;
    }
    
    return _trainingWarnWellKnownOnly;
}

/*  **************
 Training Perfect Success Rate
 *  **************/
-(void)setTrainingPerfectSuccessRate:(int)trainingPerfectSuccessRate
{
    NSString *trainingPerfectSuccessRateKey = DVT_NSUSERDEFAULTS_PERFECT_SUCCESSRATE_SETTING_KEY;
    [userDefaults setObject:[NSNumber numberWithInt:trainingPerfectSuccessRate] forKey:trainingPerfectSuccessRateKey];
    [userDefaults synchronize];
    _trainingPerfectSuccessRate = trainingPerfectSuccessRate;
}

-(int)trainingPerfectSuccessRate
{
    NSString *trainingPerfectSuccessRateKey = DVT_NSUSERDEFAULTS_PERFECT_SUCCESSRATE_SETTING_KEY;
    NSNumber *userDefaultsPerfectSuccessRate = (NSNumber *)[userDefaults objectForKey:trainingPerfectSuccessRateKey];
    if (userDefaultsPerfectSuccessRate) {
        _trainingPerfectSuccessRate = userDefaultsPerfectSuccessRate.intValue;
    } else {
        [userDefaults setObject:[NSNumber numberWithInt:DVT_DEFAULT_PERFECT_SUCCESSRATE] forKey:trainingPerfectSuccessRateKey];
        [userDefaults synchronize];
        _trainingPerfectSuccessRate = DVT_DEFAULT_PERFECT_SUCCESSRATE;
    }
    
    return _trainingPerfectSuccessRate;
}


/*  **************
 Training Auto Correction
 *  **************/
-(void)setTrainingTextInputAutoCorrection:(BOOL)trainingTextInputAutoCorrection
{
    NSString *textInputAutoCorrectionKey = DVT_NSUSERDEFAULTS_TRAINING_TEXTINPUT_AUTOCORRECTION_KEY;
    [userDefaults setObject:[NSNumber numberWithBool:trainingTextInputAutoCorrection] forKey:textInputAutoCorrectionKey];
    [userDefaults synchronize];
    _trainingTextInputAutoCorrection = trainingTextInputAutoCorrection;
}

-(BOOL)trainingTextInputAutoCorrection
{
    NSString *textInputAutoCorrectionKey = DVT_NSUSERDEFAULTS_TRAINING_TEXTINPUT_AUTOCORRECTION_KEY;
    NSNumber *userDefaultsTextInputAutoCorrection = (NSNumber *)[userDefaults objectForKey:textInputAutoCorrectionKey];
    if (userDefaultsTextInputAutoCorrection) {
        _trainingTextInputAutoCorrection = userDefaultsTextInputAutoCorrection.boolValue;
    } else {
        [userDefaults setObject:[NSNumber numberWithBool:DVT_DEFAULT_TEXTINPUT_AUTOCORRECTION] forKey:textInputAutoCorrectionKey];
        [userDefaults synchronize];
        _trainingTextInputAutoCorrection = DVT_DEFAULT_TEXTINPUT_AUTOCORRECTION;
    }
    
    return _trainingTextInputAutoCorrection;
}

@end
