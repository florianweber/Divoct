/*
SQLiteWord.h
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

#import <Foundation/Foundation.h>

typedef enum {
    WordLanguageAny = 0,
    WordLanguageGerman = 1,
	WordLanguageEnglish = 2
} WordLanguage;

typedef enum {
    SQLiteWordNormModifierSame = 0,
    SQLiteWordNormModifierFirstCharUp = 1,
	SQLiteWordNormModifierUseNameValue = 2
} SQLiteWordNormModifier;

@interface SQLiteWord : NSObject

@property (nonatomic, strong) NSNumber *uniqueId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *nameWithoutContextInfo;
@property (nonatomic, strong) NSString *nameWithoutBracketInfo;
@property (nonatomic, strong) NSString *grammarInfo;
@property (nonatomic, strong) NSString *contextInfo;
@property (nonatomic, strong) NSString *language;
@property (nonatomic, strong) NSNumber *languageCode;
@property (nonatomic, strong) NSArray *translations;

-(void)addTranslation:(SQLiteWord *)translation;

@end
