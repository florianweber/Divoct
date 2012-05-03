/*
 NormalizedStringTransformer.m
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

#import <CoreFoundation/CoreFoundation.h>
#import "NormalizedStringTransformer.h"

@implementation NormalizedStringTransformer


static NSPredicate *predicateTemplate;

+ (void)initialize {
    predicateTemplate = [NSPredicate predicateWithFormat:@"normalizedName >= $lowBound and normalizedName < $highBound"];
}

+ (Class)transformedValueClass 
{ 
    return [NSPredicate class]; 
} 

+ (BOOL)allowsReverseTransformation 
{ 
    return YES; 
} 

- (id)transformedValue:(id)value 
{ 
    return value;
}

+ (NSString *)normalizeString:(NSString *)unprocessedValue {

    if (!unprocessedValue) return nil;
    
    NSMutableString *result = [NSMutableString stringWithString:unprocessedValue];
    
    CFStringNormalize((__bridge CFMutableStringRef)result, kCFStringNormalizationFormD);
    CFStringFold((__bridge CFMutableStringRef)result, kCFCompareCaseInsensitive | kCFCompareDiacriticInsensitive | kCFCompareWidthInsensitive, NULL);

    return result;
}

// calculates the next lexically ordered string guaranteed to be greater than text
+ (NSString *)upperBoundSearchString:(NSString*)text {
    NSUInteger length = [text length];
    NSString *baseString = nil;
    NSString *incrementedString = nil;
    
    if (length < 1) {
        return text;
    } else if (length > 1) {
        baseString = [text substringToIndex:(length-1)];
    } else {
        baseString = @"";
    }
    UniChar lastChar = [text characterAtIndex:(length-1)];
    UniChar incrementedChar;
    
    // We can't do a simple lastChar + 1 operation here without taking into account
    // unicode surrogate characters (http://unicode.org/faq/utf_bom.html#34)
    
    if ((lastChar >= 0xD800UL) && (lastChar <= 0xDBFFUL)) {         // surrogate high character
        incrementedChar = (0xDBFFUL + 1);
    } else if ((lastChar >= 0xDC00UL) && (lastChar <= 0xDFFFUL)) {  // surrogate low character
        incrementedChar = (0xDFFFUL + 1);
    } else if (lastChar == 0xFFFFUL) {
        if (length > 1 ) baseString = text;
        incrementedChar =  0x1;
    } else {
        incrementedChar = lastChar + 1;
    }
    
    incrementedString = [[NSString alloc] initWithFormat:@"%@%C", baseString, incrementedChar];
    
    return incrementedString;
}

- (id)reverseTransformedValue:(id)value {

    if (!value) return nil;
    
    NSString *searchString = nil;
    NSString *lowBound = nil;
    NSString *highBound = nil;
    NSMutableDictionary *bindVariables = nil;
    

    searchString = [value description];
    lowBound = [[self class] normalizeString:searchString];
    highBound = [[self class] upperBoundSearchString:lowBound];
    
    bindVariables = [[NSMutableDictionary alloc] init];
    [bindVariables setObject:lowBound forKey:@"lowBound"];
    [bindVariables setObject:highBound forKey:@"highBound"];
    
    NSPredicate *result = [predicateTemplate predicateWithSubstitutionVariables:bindVariables];
        
    return result;
}


@end
