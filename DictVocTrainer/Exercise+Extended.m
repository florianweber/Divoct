/*
Exercise+Extended.m
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

#import "Exercise+Extended.h"
#import "SQLiteWord.h"
#import "DictVocDictionary.h"
#import "GlobalDefinitions.h"

@implementation Exercise (Extended)
@dynamic word;
@dynamic successRate;

-(SQLiteWord *)word
{
    //annotation: this might lead to a performance problem, but we will see
    return [[DictVocDictionary instance] wordByUniqueId:self.wordUniqueId];
}

-(NSNumber *)successRate
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *perfectSuccessRateKey = DVT_PERFECT_SUCCESSRATE_SETTING;
    NSNumber *perfectSuccessRateSetting = (NSNumber *)[defaults objectForKey:perfectSuccessRateKey];
    
    NSNumber *successRate;
    
    if (self.countCorrect.intValue == 0) {
        successRate = [NSNumber numberWithFloat:0.0];
    } else if ((self.countCorrect.intValue - self.countWrong.intValue) >= perfectSuccessRateSetting.intValue) {
        successRate = [NSNumber numberWithFloat:1.0];
    } else {
        successRate = [NSNumber numberWithFloat:(self.countCorrect.floatValue / self.exerciseCount.floatValue)];
    }
    
    return successRate;
}

-(NSString *) description {
    return [NSString stringWithFormat:@"Word name: %@, Exercise count: %i, Count correct: %i, Count wrong: %i, SuccessRate: %f", self.word.name, self.exerciseCount.intValue, self.countCorrect.intValue, self.countWrong.intValue, self.successRate.floatValue];
}


@end
