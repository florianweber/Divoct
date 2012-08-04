/*
SQLiteWord.m
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

#import "SQLiteWord.h"
#import "DictVocDictionary.h"

@interface SQLiteWord()


@end

@implementation SQLiteWord
@synthesize uniqueId = _uniqueId;
@synthesize name = _name;
@synthesize grammarInfo = _grammarInfo;
@synthesize language = _language;
@synthesize languageCode = _languageCode;
@synthesize translations = _translations;
@synthesize contextInfo = _contextInfo;
@synthesize nameWithoutContextInfo = _nameWithoutContextInfo;

-(NSString *)language
{
    if (!_language) {
        switch (self.languageCode.intValue) {
            case WordLanguageEnglish:
                _language = @"English";
                break;
                
            case WordLanguageGerman:
                _language = @"German";
                break;
                
            case WordLanguageAny:
                _language = @"Unknown";
                break;
                
            default:
                _language = @"Unknown";
                break;
        }
    }
    return _language;
}

-(NSString *)contextInfo
{
    if (!_contextInfo) {
        NSRange startOfContextRange = [self.name rangeOfString:@"["];
        NSRange endOfContextRange = [self.name rangeOfString:@"]"];
        
        if ((startOfContextRange.location != NSNotFound) && (endOfContextRange.location != NSNotFound)) {
            NSRange contextInfoRange;
            contextInfoRange.location = startOfContextRange.location;
            contextInfoRange.length = endOfContextRange.location - startOfContextRange.location + 1;
            
            self.contextInfo = [self.name substringWithRange:contextInfoRange];
        }
    }
    return _contextInfo;
}

-(NSString *)nameWithoutContextInfo
{
    if (!_nameWithoutContextInfo) {
        if (self.contextInfo) {
            self.nameWithoutContextInfo = [self.name stringByReplacingOccurrencesOfString:self.contextInfo withString:@""];
            self.nameWithoutContextInfo = [self.nameWithoutContextInfo stringByReplacingOccurrencesOfString:@"  " withString:@" "];
            self.nameWithoutContextInfo = [self.nameWithoutContextInfo stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        } else {
            self.nameWithoutContextInfo = self.name;
        }
    }
    return _nameWithoutContextInfo;
}

-(NSString *)nameWithoutBracketInfo
{
    if (!_nameWithoutBracketInfo) {
        NSError *error;
        NSRegularExpression *contentOfBrackets = [NSRegularExpression regularExpressionWithPattern:@"[\\(\\{\\[].*?[\\)\\}\\]]"
                                                                                                options:NSRegularExpressionCaseInsensitive
                                                                                                  error:&error];
        
        _nameWithoutBracketInfo = [[contentOfBrackets stringByReplacingMatchesInString:self.name options:0 range:NSMakeRange(0, [self.name length])  withTemplate:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return _nameWithoutBracketInfo;
}

-(NSArray *)translations
{
    if (!_translations) {
        _translations = [NSArray array];
    }
    return _translations;
}

-(void)addTranslation:(SQLiteWord *)translation
{
    NSMutableArray *mutableTranslations = [self.translations mutableCopy];
    [mutableTranslations addObject:translation];
    self.translations = mutableTranslations;
}

@end
