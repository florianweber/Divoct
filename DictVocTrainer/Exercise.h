/*
  Exercise.h
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
#import <CoreData/CoreData.h>

@class Collection, Translation;

@interface Exercise : NSManagedObject

@property (nonatomic, retain) NSNumber * countCorrect;
@property (nonatomic, retain) NSNumber * countWrong;
@property (nonatomic, retain) NSNumber * createdAtLatitude;
@property (nonatomic, retain) NSNumber * createdAtLongitude;
@property (nonatomic, retain) NSNumber * exerciseCount;
@property (nonatomic, retain) NSDate * lastExercised;
@property (nonatomic, retain) NSDate * lastLookedUp;
@property (nonatomic, retain) NSDate * lastTimeCorrect;
@property (nonatomic, retain) NSDate * lastTimeWrong;
@property (nonatomic, retain) NSNumber * lookupCount;
@property (nonatomic, retain) NSNumber * wordUniqueId;
@property (nonatomic, retain) NSSet *collections;
@property (nonatomic, retain) NSSet *trainingTranslations;
@end

@interface Exercise (CoreDataGeneratedAccessors)

- (void)addCollectionsObject:(Collection *)value;
- (void)removeCollectionsObject:(Collection *)value;
- (void)addCollections:(NSSet *)values;
- (void)removeCollections:(NSSet *)values;

- (void)addTrainingTranslationsObject:(Translation *)value;
- (void)removeTrainingTranslationsObject:(Translation *)value;
- (void)addTrainingTranslations:(NSSet *)values;
- (void)removeTrainingTranslations:(NSSet *)values;

@end
