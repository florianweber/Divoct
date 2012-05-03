/*
  DictVocTrainer.m
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

#import "DictVocTrainer.h"
#import "GlobalDefinitions.h"
#import "Logging.h"
#import "Exercise.h"
#import "Collection.h"
#import "TrainingResult.h"
#import "Translation.h"

@interface DictVocTrainer()

@end

@implementation DictVocTrainer
@synthesize dictVocTrainerDB = _dictVocTrainerDB;

static DictVocTrainer *singleton;

#pragma mark - Initialization

+(void)initialize 
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        singleton = [[DictVocTrainer alloc] init];
    }
}

+(DictVocTrainer *)instance
{
    return singleton;
}


#pragma mark - My messages

#pragma mark - My messages - Core Data general

-(void)openDictVocTrainerDBUsingBlock:(completion_block_t)completionBlock
{
    UIManagedDocument *dvtDB = self.dictVocTrainerDB;
    
    if (!dvtDB) {
        NSURL *documentsDirURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        
        //init dict voc trainer document
        NSURL *dictVocTrainerDBURL = [documentsDirURL URLByAppendingPathComponent:DVT_TRAINER_DB_FILE_NAME];
        LogDebug(@"DictVocTrainerDBURL: %@", dictVocTrainerDBURL.path);
        dvtDB = [[UIManagedDocument alloc] initWithFileURL:dictVocTrainerDBURL];
    }
    
    //check if file exists and document state
    if (![[NSFileManager defaultManager] fileExistsAtPath:[dvtDB.fileURL path]]) {
        [dvtDB saveToURL:dvtDB.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if(success) {
                LogDebug(@"DictVocTrainer file created successfully at path: %@", dvtDB.fileURL.path);
                self.dictVocTrainerDB = dvtDB; 
                completionBlock(nil);
            } else {
                NSString *errorString = [NSString stringWithFormat:@"Error creating DictVocTrainer file at path: %@", dvtDB.fileURL.path];
                LogError(@"%@", errorString);
                
                NSMutableDictionary* errorDetails = [NSMutableDictionary dictionary];
                [errorDetails setValue:errorString forKey:NSLocalizedDescriptionKey];
                
                NSError *error = [NSError errorWithDomain:@"DVT" code:100 userInfo:errorDetails];
                completionBlock(error);
            }
        }];
    } else if (dvtDB.documentState == UIDocumentStateClosed) {
        [dvtDB openWithCompletionHandler:^(BOOL success) {
            if(success) {
                LogDebug(@"DictVocTrainer file opened successfully.");
                self.dictVocTrainerDB = dvtDB;
                completionBlock(nil);
            } else {
                NSString *errorString = [NSString stringWithFormat:@"Error opening DictVocTrainer file at path: %@", dvtDB.fileURL.path];
                LogError(@"%@", errorString);
                
                NSMutableDictionary* errorDetails = [NSMutableDictionary dictionary];
                [errorDetails setValue:errorString forKey:NSLocalizedDescriptionKey];
                
                NSError *error = [NSError errorWithDomain:@"DVT" code:100 userInfo:errorDetails];
                completionBlock(error);
            }
        }];
    } else if (dvtDB.documentState == UIDocumentStateNormal) {
        LogDebug(@"DictVocTrainer already open.");
        if (dvtDB != self.dictVocTrainerDB) {
            self.dictVocTrainerDB = dvtDB;
        }
        completionBlock(nil);
    } else {
        NSString *errorString = [NSString stringWithFormat:@"Error opening DictVocTrainer file due to inconsistent document state at path: %@", dvtDB.fileURL.path];
        LogError(@"%@", errorString);
        
        NSMutableDictionary* errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:errorString forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:@"DVT" code:100 userInfo:errorDetails];
        completionBlock(error);
    }
}

-(void)saveDictVocTrainerDBUsingBlock:(completion_block_t)completionBlock
{
    if (self.dictVocTrainerDB) {
        [self.dictVocTrainerDB saveToURL:self.dictVocTrainerDB.fileURL 
                        forSaveOperation:UIDocumentSaveForOverwriting 
                       completionHandler:^(BOOL success) {
                                              if (success) {
                                                  LogDebug(@"DictVocTrainerDB saved successfully.");
                                                  completionBlock(nil);
                                              } else {
                                                  NSString *errorString = [NSString stringWithFormat:@"Error saving DictVocTrainer DB at path: %@", self.dictVocTrainerDB.fileURL.path];
                                                  LogError(@"%@", errorString);
                                                  
                                                  NSMutableDictionary* errorDetails = [NSMutableDictionary dictionary];
                                                  [errorDetails setValue:errorString forKey:NSLocalizedDescriptionKey];
                                                  
                                                  NSError *error = [NSError errorWithDomain:@"DVT" code:100 userInfo:errorDetails];
                                                  completionBlock(error);
                                              } 
                                        }];
    } else {
        NSString *errorString = [NSString stringWithFormat:@"Error saving DictVocTrainer DB as it has not been initialized yet."];
        LogError(@"%@", errorString);
        
        NSMutableDictionary* errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:errorString forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:@"DVT" code:100 userInfo:errorDetails];
        completionBlock(error);
    }
}

-(void)closeDictVocTrainerDBUsingBlock:(completion_block_t)completionBlock
{
    if (self.dictVocTrainerDB) {
        if (self.dictVocTrainerDB.documentState == UIDocumentStateClosed) {
            LogDebug(@"DictVocTrainerDB already closed.");
            completionBlock(nil);
        } else {
            [self.dictVocTrainerDB closeWithCompletionHandler:^(BOOL success) {
                if (success) {
                    LogDebug(@"DictVocTrainerDB closed successfully.");
                    completionBlock(nil);
                } else {
                    NSString *errorString = [NSString stringWithFormat:@"Error closing DictVocTrainer DB at path: %@", self.dictVocTrainerDB.fileURL.path];
                    LogError(@"%@", errorString);
                    
                    NSMutableDictionary* errorDetails = [NSMutableDictionary dictionary];
                    [errorDetails setValue:errorString forKey:NSLocalizedDescriptionKey];
                    
                    NSError *error = [NSError errorWithDomain:@"DVT" code:100 userInfo:errorDetails];
                    completionBlock(error);
                } 
            }];
        }
    } else {
        NSString *errorString = [NSString stringWithFormat:@"Error closing DictVocTrainer DB as it has not been initialized yet."];
        LogError(@"%@", errorString);
        
        NSMutableDictionary* errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:errorString forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:@"DVT" code:100 userInfo:errorDetails];
        completionBlock(error);

    }
}

#pragma mark - My messages - Collections

- (Collection *)readCollectionWithName:(NSString *)name
{
    Collection *collection = nil;
    NSString *cleanName = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (!(cleanName && [cleanName length])) {
        LogDebug(@"Your name for the collection is invalid. Nothing will happen.");
    } else {
        if (!self.dictVocTrainerDB) {
            LogError(@"DictVocTrainer DB not initialized yet.");
        } else {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Collection"];
            request.predicate = [NSPredicate predicateWithFormat:@"name = %@", cleanName];
            
            NSError *error = nil;
            NSArray *collections = [self.dictVocTrainerDB.managedObjectContext executeFetchRequest:request error:&error];
            
            if (!collections || [collections count] > 1) {
                LogError(@"Error creating / reading collection '%@', exists %i times, error: %@", cleanName, [collections count], error);
            } else {
                LogDebug(@"Read collection from database with name: %@", cleanName);
                collection = [collections lastObject];
            }
        }
    }
    return collection;
}

- (Collection *)collectionWithName:(NSString *)name
{
    Collection *collection = nil;
    NSString *cleanName = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (!(cleanName && [cleanName length])) {
        LogDebug(@"Your name for the collection is invalid. Nothing will happen.");
    } else {
        if (!self.dictVocTrainerDB) {
            LogError(@"DictVocTrainer DB not initialized yet.");
        } else {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Collection"];
            request.predicate = [NSPredicate predicateWithFormat:@"name = %@", cleanName];
            
            NSError *error = nil;
            NSArray *collections = [self.dictVocTrainerDB.managedObjectContext executeFetchRequest:request error:&error];
            
            if (!collections || [collections count] > 1) {
                LogError(@"Error creating / reading collection '%@', exists %i times, error: %@", cleanName, [collections count], error);
            } else if ([collections count] == 0) {
                collection = [NSEntityDescription insertNewObjectForEntityForName:@"Collection" inManagedObjectContext:self.dictVocTrainerDB.managedObjectContext];
                collection.name = cleanName;
                if ([cleanName isEqualToString:NSLocalizedString(@"RECENTS_TITLE", nil)]) {
                    collection.desc = NSLocalizedString(@"RECENTS_DESC", nil);
                }
                LogDebug(@"Inserted collection into database with name: %@", cleanName);
            } else {
                LogDebug(@"Read collection from database with name: %@", cleanName);
                collection = [collections lastObject];
            }
        }
    }
    return collection;
}

//returns an array of Collection objects 
- (NSArray *)allCollections
{
    NSArray *collections = nil;
    
    if (!self.dictVocTrainerDB) {
        LogError(@"DictVocTrainer DB not initialized yet.");
    } else {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Collection"];
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
        request.sortDescriptors = sortDescriptors;
        
        NSError *error = nil;
        collections = [self.dictVocTrainerDB.managedObjectContext executeFetchRequest:request error:&error];
        
        if (!collections) {
            LogError(@"Error reading collections, error: %@", error);
        } else if ([collections count] == 0) {
            LogDebug(@"No collections found.");
        } else if ([collections count] > 0) {
            LogDebug(@"Found %i collections.", [collections count]);
        }
    }
    
    return collections;
}

- (NSArray *)allCollectionsExceptRecents
{
    NSArray *collections = nil;
    
    if (!self.dictVocTrainerDB) {
        LogError(@"DictVocTrainer DB not initialized yet.");
    } else {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Collection"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name != %@", NSLocalizedString(@"RECENTS_TITLE", nil)];
        request.predicate = predicate;
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
        request.sortDescriptors = sortDescriptors;
        
        NSError *error = nil;
        collections = [self.dictVocTrainerDB.managedObjectContext executeFetchRequest:request error:&error];
        
        if (!collections) {
            LogError(@"Error reading collections, error: %@", error);
        } else if ([collections count] == 0) {
            LogDebug(@"No collections found.");
        } else if ([collections count] > 0) {
            LogDebug(@"Found %i collections.", [collections count]);
        }
    }
    
    return collections;
}


- (void)deleteCollection:(Collection *)collection
{
    [self.dictVocTrainerDB.managedObjectContext deleteObject:collection];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:DVT_COLLECTION_NOTIFICATION_DELETED object:collection]];
    [self saveDictVocTrainerDBUsingBlock:^(NSError *error){}];
}

- (BOOL)isWordWithUniqueId:(NSNumber *)wordUniqueId partOfCollection:(Collection *)collection
{
    for (Exercise *exercise in collection.exercises) {
        if ([exercise.wordUniqueId isEqualToNumber:wordUniqueId]) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - My messages - Exercises

- (Exercise *)exerciseWithWordUniqueId:(NSNumber *)uniqueId
{
    Exercise *exercise = nil;
    if (!self.dictVocTrainerDB) {
        LogError(@"DictVocTrainer DB not initialized yet.");
    } else {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Exercise"];
        request.predicate = [NSPredicate predicateWithFormat:@"wordUniqueId = %i", [uniqueId intValue]];
                
        NSError *error = nil;
        NSArray *exercises = [self.dictVocTrainerDB.managedObjectContext executeFetchRequest:request error:&error];
        
        if (!exercises || [exercises count] > 1) {
            LogError(@"Error creating / reading exercise %i, exists %i times, error: %@", [uniqueId intValue], [exercises count], error);
        } else if ([exercises count] == 0) {
            exercise = [NSEntityDescription insertNewObjectForEntityForName:@"Exercise" inManagedObjectContext:self.dictVocTrainerDB.managedObjectContext];
            exercise.wordUniqueId = uniqueId;
            exercise.lastLookedUp = [NSDate date];
            //todo: add location info
            LogDebug(@"Inserted exercise into database with id: %i", [uniqueId intValue]);
        } else {
            LogDebug(@"Read exercise from database with id: %i", [uniqueId intValue]);
            exercise = [exercises lastObject];
            exercise.lastLookedUp = [NSDate date];
            exercise.lookupCount = [NSNumber numberWithInt:[exercise.lookupCount intValue] + 1];
        }
        [self saveDictVocTrainerDBUsingBlock:^(NSError *error){}];
    }
    return exercise;
}

//returns an array of Exercise objects 
- (NSArray *)allExercises
{
    NSArray *exercises = nil;
    
    if (!self.dictVocTrainerDB) {
        LogError(@"DictVocTrainer DB not initialized yet.");
    } else {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Exercise"];
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"lastLookedUp" ascending:YES]];
        request.sortDescriptors = sortDescriptors;
        
        NSError *error = nil;
        exercises = [self.dictVocTrainerDB.managedObjectContext executeFetchRequest:request error:&error];
        
        if (!exercises) {
            LogError(@"Error reading exercises, error: %@", error);
        } else if ([exercises count] == 0) {
            LogDebug(@"No exercises found.");
        } else if ([exercises count] > 0) {
            LogDebug(@"Found %i exercises.", [exercises count]);
        }
    }
    
    return exercises;
}

- (NSArray *)recentExercises
{
    Collection *recentCollection = [self collectionWithName:NSLocalizedString(@"RECENTS_TITLE", nil)];
    return [recentCollection.exercises array];
}

- (NSOrderedSet *)exercisesInCollectionWithName:(NSString *)collectionName
{
    Collection *collection = [self collectionWithName:collectionName];
    return collection.exercises;
}

- (void)deleteExercise:(Exercise *)exercise fromCollection:(Collection *)collection
{
    [exercise removeCollectionsObject:collection];
    
    if (![exercise.collections count]) {
        [self.dictVocTrainerDB.managedObjectContext deleteObject:exercise];
    }
    
    [self saveDictVocTrainerDBUsingBlock:^(NSError *error){}];
}

#pragma mark - My messages - TrainingResult

- (TrainingResult *)insertTrainingResultWithCountWrong:(NSNumber *)countWrong
                                          countCorrect:(NSNumber *)countCorrect
                                            countWords:(NSNumber *)countTrained
                                            collection:(Collection *)collection
                                          trainingDate:(NSDate *)trainingDate
{
    TrainingResult *trainingResult = nil;
    if (!self.dictVocTrainerDB) {
        LogError(@"DictVocTrainer DB not initialized yet.");
    } else {
        trainingResult = [NSEntityDescription insertNewObjectForEntityForName:@"TrainingResult" inManagedObjectContext:self.dictVocTrainerDB.managedObjectContext];
        trainingResult.countWrong = countWrong;
        trainingResult.countCorrect = countCorrect;
        trainingResult.countTrained = countTrained;
        trainingResult.collection = collection;
        trainingResult.trainingDate = trainingDate;
        
        [self saveDictVocTrainerDBUsingBlock:^(NSError *error){}];
    }
    return trainingResult;
}

//will not create one if not existing
- (TrainingResult *)trainingResultWithObjectId:(NSManagedObjectID *)objectId
{
    TrainingResult *trainingResult = nil;
    if (!self.dictVocTrainerDB) {
        LogError(@"DictVocTrainer DB not initialized yet.");
    } else {
        NSError *error;
        if (objectId) {
            trainingResult = (TrainingResult *)[self.dictVocTrainerDB.managedObjectContext existingObjectWithID:objectId error:&error];
        }
    }
    return trainingResult;
}

#pragma mark - My messages - Translation

- (Translation *)translationWithUniqueId:(NSNumber *)wordUniqueId
{
    Translation *translation = nil;
    
    if (!self.dictVocTrainerDB) {
        LogError(@"DictVocTrainer DB not initialized yet.");
    } else {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Translation"];
        request.predicate = [NSPredicate predicateWithFormat:@"uniqueId = %i", [wordUniqueId intValue]];
        
        NSError *error = nil;
        NSArray *translations = [self.dictVocTrainerDB.managedObjectContext executeFetchRequest:request error:&error];
        
        if (!translations || [translations count] > 1) {
            LogError(@"Error creating / reading translation '%i', exists %i times, error: %@", [wordUniqueId intValue], [translations count], error);
        } else if ([translations count] == 0) {
            translation = [NSEntityDescription insertNewObjectForEntityForName:@"Translation" inManagedObjectContext:self.dictVocTrainerDB.managedObjectContext];
            translation.uniqueId = wordUniqueId;
            LogDebug(@"Inserted translation into database with id: %i", [wordUniqueId intValue]);
        } else {
            LogDebug(@"Read translation from database with id: %i", [wordUniqueId intValue]);
            translation = [translations lastObject];
        }
    }
    
    return translation;
}

- (void)deleteTranslation:(Translation *)translation
{
    [self.dictVocTrainerDB.managedObjectContext deleteObject:translation];
    [self saveDictVocTrainerDBUsingBlock:^(NSError *error){}];
}



-(void)dealloc
{
    [self saveDictVocTrainerDBUsingBlock:^(NSError *error){
        if (!error) {
            [self.dictVocTrainerDB closeWithCompletionHandler:^(BOOL success){
                self.dictVocTrainerDB = nil;
            }];
        }
    }];
    
}


@end
