/*
 DictVocTrainer.h
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
#import "Exercise.h"
#import "TrainingResult.h"
#import "Translation.h"
#import "Collection.h"

typedef void (^completion_block_t) (NSError *error);

@interface DictVocTrainer : NSObject
@property (strong) UIManagedDocument *dictVocTrainerDB;

+(DictVocTrainer *)instance;

-(void)openDictVocTrainerDBUsingBlock:(completion_block_t)completionBlock;
-(void)saveDictVocTrainerDBUsingBlock:(completion_block_t)completionBlock;
-(void)closeDictVocTrainerDBUsingBlock:(completion_block_t)completionBlock;

-(NSArray *)allExercises;
-(NSArray *)recentExercises;
-(Exercise *)exerciseWithWordUniqueId:(NSNumber *)uniqueId;
-(void)deleteExercise:(Exercise *)exercise fromCollection:(Collection *)collection;
-(void)resetAllExerciseStatistics;
-(NSOrderedSet *)exercisesInCollectionWithName:(NSString *)collectionName;
-(Collection *)collectionWithName:(NSString *)name;
-(Collection *)readCollectionWithName:(NSString *)name;
-(NSArray *)allCollections;
-(NSArray *)allCollectionsExceptRecents;
-(void)deleteCollection:(Collection *)collection;
-(BOOL)isWordWithUniqueId:(NSNumber *)wordUniqueId partOfCollection:(Collection *)collection;
-(TrainingResult *)insertTrainingResultWithCountWrong:(NSNumber *)countWrong
                                          countCorrect:(NSNumber *)countCorrect
                                            countWords:(NSNumber *)countTrained
                                            collection:(Collection *)collection
                                          trainingDate:(NSDate *)trainingDate;
-(TrainingResult *)trainingResultWithObjectId:(NSManagedObjectID *)objectId;
-(NSArray *)allTrainingResults;
-(void)deleteAllTrainingResults;
-(Translation *)translationWithUniqueId:(NSNumber *)wordUniqueId;
-(void)deleteTranslation:(Translation *)translation;


@end
