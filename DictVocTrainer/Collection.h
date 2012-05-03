/*
  Collection.h
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

@class Exercise, TrainingResult;

@interface Collection : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSDate * lastTrained;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSOrderedSet *exercises;
@property (nonatomic, retain) NSSet *trainingResults;
@end

@interface Collection (CoreDataGeneratedAccessors)

- (void)insertObject:(Exercise *)value inExercisesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromExercisesAtIndex:(NSUInteger)idx;
- (void)insertExercises:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeExercisesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInExercisesAtIndex:(NSUInteger)idx withObject:(Exercise *)value;
- (void)replaceExercisesAtIndexes:(NSIndexSet *)indexes withExercises:(NSArray *)values;
- (void)addExercisesObject:(Exercise *)value;
- (void)removeExercisesObject:(Exercise *)value;
- (void)addExercises:(NSOrderedSet *)values;
- (void)removeExercises:(NSOrderedSet *)values;
- (void)addTrainingResultsObject:(TrainingResult *)value;
- (void)removeTrainingResultsObject:(TrainingResult *)value;
- (void)addTrainingResults:(NSSet *)values;
- (void)removeTrainingResults:(NSSet *)values;

@end
