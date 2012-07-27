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
    NSNumber *successRate = [NSNumber numberWithFloat:0.0];
    
    if ((self.countWrong.floatValue > 0.0) && (self.countCorrect.floatValue > 0.0))
    {
        successRate = [NSNumber numberWithFloat:(self.countCorrect.floatValue / self.countWrong.floatValue)];
        
    } else if (self.countWrong.floatValue > 0.0 && self.countCorrect.floatValue <= 0.0) {
        successRate = [NSNumber numberWithFloat:(0.0 - self.countWrong.floatValue)];
        
    } else if (self.countWrong.floatValue <= 0 && self.countCorrect.floatValue > 0) {
        successRate = self.countCorrect;
        
    } else {
        successRate = [NSNumber numberWithFloat:0.0];
    }
    
    
    return successRate;
}


@end
