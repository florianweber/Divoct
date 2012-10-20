/*
 DictVocDictionary.m
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

#import <sqlite3.h>
#import "DictVocDictionary.h"
#import "GlobalDefinitions.h"
#import "Logging.h"
#import "ZipFile.h"
#import "ZipWriteStream.h"
#import "ZipReadStream.h"
#import "FileInZipInfo.h"
#import "NormalizedStringTransformer.h"
#import "SQLiteWord.h"
#import "DictVocTrainer.h"

@interface DictVocDictionary()


- (NSString *)unzipDatabaseFrom:(NSString *)sourceFilePath
                             to:(NSString *)destinationFilePath;

@end

@implementation DictVocDictionary
static DictVocDictionary *singleton;
sqlite3 *database;
dispatch_queue_t queryQueue;

#pragma mark - Initialization

+(void)initialize 
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        singleton = [[DictVocDictionary alloc] init];
    }
}

-(id)init
{
    if (self = [super init]) {
        queryQueue = dispatch_queue_create("DictVocDictionary Query Queue", NULL);
    }
    
    return self;
}

+(DictVocDictionary *)instance
{
    return singleton;
}

#pragma mark - Initialization / Deinit

- (BOOL)firstTimeSetupRequired
{
    NSString *destinationFilePath = [[[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject] path] stringByAppendingPathComponent:DVT_DB_FILE_NAME];
    LogDebug(@"Checking database path: %@", destinationFilePath);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:destinationFilePath]) {
        return NO;
    } else {
        return YES;
    }
}
    
- (void)setupDatabaseWithCompletionBlock:(db_init_block_t)completionBlock
{
    NSError *error = nil;
    
    if ([self firstTimeSetupRequired]) {
        
        NSString *destinationFilePath   = [[[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject] path] stringByAppendingPathComponent:DVT_DB_FILE_NAME];
        NSString *sourceFilePath        = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DVT_DB_FILE_NAME] stringByAppendingPathExtension:@"zip"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:sourceFilePath]) {
            NSString *errorString = [NSString stringWithFormat:@"Can't find source database: %@", sourceFilePath];
            LogError(@"%@", errorString);
            
            NSMutableDictionary* errorDetails = [NSMutableDictionary dictionary];
            [errorDetails setValue:errorString forKey:NSLocalizedDescriptionKey];
            
            error = [NSError errorWithDomain:@"DVT" code:100 userInfo:errorDetails];
            completionBlock(error);
        } else {
            dispatch_queue_t dbUnzipWorker = dispatch_queue_create("DB Unzip Worker", NULL);
            dispatch_async(dbUnzipWorker, ^{
                NSString *databaseFileName = [self unzipDatabaseFrom:sourceFilePath to:destinationFilePath];
                NSError *openDBError = [self openDatabaseWithFileName:databaseFileName];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(openDBError);
                });
            });
            dispatch_release(dbUnzipWorker);
        }
    } else {
        completionBlock(error);
    }
}

- (NSError *)openDatabaseWithFileName:(NSString *)fileName
{   
    NSError *error = nil;
    
    if (!database) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *dbPath = [[NSString alloc]initWithString:[documentsDirectory stringByAppendingPathComponent:DVT_DB_FILE_NAME]];
        
        if (sqlite3_open([dbPath UTF8String], &database) == SQLITE_OK) {
            LogDebug(@"Database opened / created if necessary successfully.");
        } else {
            NSString *errorString = @"Error opening database.";
            LogError(@"%@", errorString);
            
            NSMutableDictionary* errorDetails = [NSMutableDictionary dictionary];
            [errorDetails setValue:errorString forKey:NSLocalizedDescriptionKey];
            
            error = [NSError errorWithDomain:@"DVT" code:100 userInfo:errorDetails];
        }
    }
    
    return error;
}

//source database zip file has to be placed in the root folder of the main bundle (where the source code is placed)
//returns database file name relative to documents directory
- (NSString *)unzipDatabaseFrom:(NSString *)sourceFilePath
                             to:(NSString *)destinationFilePath
{
    ZipFile *unzipFile= [[ZipFile alloc] initWithFileName:sourceFilePath mode:ZipFileModeUnzip];
    //info: the zip file will only contain one file, which is "persistentStore", but the fileInfo includes the path beginning in the documents directory
    [unzipFile goToFirstFileInZip];
    
    FileInZipInfo *currentFileInfo = [unzipFile getCurrentFileInZipInfo];
    
    //info: removing last path component first, because it is included in currentFileInfo.name
    NSString *writePath = [[destinationFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:currentFileInfo.name];
    LogDebug(@"Database unzipped to path: %@", writePath);
    
    //Create file (needs to be created before NSFileHandle can write to it)
    [[NSFileManager defaultManager] createFileAtPath:writePath contents:nil attributes:nil];
    
    //Write to persistent store file
    NSFileHandle *fileWriter = [NSFileHandle fileHandleForWritingAtPath:writePath];
    
    ZipReadStream *read= [unzipFile readCurrentFileInZip];
    NSMutableData *buffer= [[NSMutableData alloc] initWithLength:1024];
    
    // Read-then-write buffered loop (reads from the zip file, writes to destination in buffer sizes)
    do {
        
        // Reset buffer length
        [buffer setLength:1024];
        
        // Expand next chunk of bytes
        int bytesRead= [read readDataWithBuffer:buffer];
        if (bytesRead > 0) {
            
            // Write what we have read
            [buffer setLength:bytesRead];
            [fileWriter writeData:buffer];
            
        } else
            break;
        
    } while (YES);
    
    // Clean up
    [read finishedReading];
    [unzipFile close];
    
    [fileWriter closeFile];
    
    //calculate return value
    return currentFileInfo.name;
}

-(void)closeDatabase
{
    sqlite3_close(database);    
}

-(void)dealloc
{
    [self closeDatabase];
    dispatch_release(queryQueue);
}

#pragma mark - SQLite queries

-(int)maxIdInWords
{
    int maxId = 0;
    NSString *queryStatement = [NSString stringWithFormat:@"SELECT max(uniqueid) FROM words"];            
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [queryStatement UTF8String], -1, &statement, NULL) == SQLITE_OK)
    {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            maxId = sqlite3_column_int(statement, 0);
        }
        sqlite3_finalize(statement);
    }
    
    return maxId;
}

-(SQLiteWord *)getRelationsShipsForWord:(SQLiteWord *)word 
{
    //translations
    NSString *queryStatement = [NSString stringWithFormat:@"SELECT w2.uniqueid, w2.name, w2.language, w2.grammarInfo FROM words w2, translations t WHERE t.word == %i AND w2.uniqueid == t.translation;", word.uniqueId.intValue];
    
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [queryStatement UTF8String], -1, &statement, NULL) == SQLITE_OK)
    {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            SQLiteWord *translation = [[SQLiteWord alloc] init];
            translation.uniqueId = [NSNumber numberWithInt:sqlite3_column_int(statement, 0)];
            translation.name = [[NSString alloc] initWithBytes:sqlite3_column_text(statement, 1) length:sqlite3_column_bytes(statement, 1) encoding:NSUTF8StringEncoding];
            translation.languageCode =  [NSNumber numberWithInt:sqlite3_column_int(statement, 2)];
            const void *grammarInfoBytes = sqlite3_column_text(statement, 3);
            if (grammarInfoBytes) {
                translation.grammarInfo = [[NSString alloc] initWithBytes:grammarInfoBytes length:sqlite3_column_bytes(statement, 3) encoding:NSUTF8StringEncoding];
            }
            
            [word addTranslation:translation];
        }
        sqlite3_finalize(statement);
    }
    
    return word;
}

-(SQLiteWord *)getRelationsShipsForWord:(SQLiteWord *)word withTranslationIds:(NSArray *)wordUniqueIds
{
    //translations
    NSString *wordUniqueIdsString = @"";
    for (NSNumber *uniqueId in wordUniqueIds) {
        wordUniqueIdsString = [wordUniqueIdsString stringByAppendingFormat:@"%i,", [uniqueId intValue]];
    }
    wordUniqueIdsString = [wordUniqueIdsString substringToIndex:wordUniqueIdsString.length-1];
    
    NSString *queryStatement = [NSString stringWithFormat:@"SELECT w2.uniqueid, w2.name, w2.language, w2.grammarInfo FROM words w2, translations t WHERE t.word == %i AND w2.uniqueid == t.translation AND t.translation IN (%@);", word.uniqueId.intValue, wordUniqueIdsString];
    
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [queryStatement UTF8String], -1, &statement, NULL) == SQLITE_OK)
    {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            SQLiteWord *translation = [[SQLiteWord alloc] init];
            translation.uniqueId = [NSNumber numberWithInt:sqlite3_column_int(statement, 0)];
            translation.name = [[NSString alloc] initWithBytes:sqlite3_column_text(statement, 1) length:sqlite3_column_bytes(statement, 1) encoding:NSUTF8StringEncoding];
            translation.languageCode =  [NSNumber numberWithInt:sqlite3_column_int(statement, 2)];
            const void *grammarInfoBytes = sqlite3_column_text(statement, 3);
            if (grammarInfoBytes) {
                translation.grammarInfo = [[NSString alloc] initWithBytes:grammarInfoBytes length:sqlite3_column_bytes(statement, 3) encoding:NSUTF8StringEncoding];
            }
            
            [word addTranslation:translation];
        }
        sqlite3_finalize(statement);
    }
    
    return word;
}


-(void)getWordsBeginningWithTerm:(NSString *)term 
                   withRelationsships:(BOOL)withRel
                           usingBlock:(db_query_wordsArray_completion_block_t)resultsBlock
{
    dispatch_async(queryQueue, ^{
        NSMutableArray *results = [[NSMutableArray alloc] init];
        NSString *lowBound = [NormalizedStringTransformer normalizeString:term];
        NSString *highBound = [NormalizedStringTransformer upperBoundSearchString:lowBound];
        
        NSString *queryStatement = [NSString stringWithFormat:@"SELECT DISTINCT w.uniqueid, w.name, w.language, w.grammarInfo FROM words AS w, searchterms AS s WHERE (s.normalizedname >= '%@' AND s.normalizedname < '%@') AND (s.word == w.uniqueid)", lowBound, highBound];
        
        //query words
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [queryStatement UTF8String], -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                SQLiteWord *word = [[SQLiteWord alloc] init];
                word.uniqueId = [NSNumber numberWithInt:sqlite3_column_int(statement, 0)];
                word.name = [[NSString alloc] initWithBytes:sqlite3_column_text(statement, 1) length:sqlite3_column_bytes(statement, 1) encoding:NSUTF8StringEncoding];
                word.languageCode =  [NSNumber numberWithInt:sqlite3_column_int(statement, 2)];
                const void *grammarInfoBytes = sqlite3_column_text(statement, 3);
                if (grammarInfoBytes) {
                    word.grammarInfo = [[NSString alloc] initWithBytes:grammarInfoBytes length:sqlite3_column_bytes(statement, 3) encoding:NSUTF8StringEncoding];
                }
                
                [results addObject:word];
            }
            sqlite3_finalize(statement);
        }
        
        //query relationships
        if (withRel) {
            for (SQLiteWord *word in results) {
                [self getRelationsShipsForWord:word];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            resultsBlock(term, results);
        });
        
    });
}

-(SQLiteWord *)wordByUniqueId:(NSNumber *)wordUniqueId
{
    SQLiteWord *word = nil;
    
    NSString *queryStatement = [NSString stringWithFormat:@"SELECT uniqueid, name, language, grammarInfo FROM words WHERE uniqueid = %i", [wordUniqueId intValue]];            
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [queryStatement UTF8String], -1, &statement, NULL) == SQLITE_OK)
    {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            word = [[SQLiteWord alloc] init];
            word.uniqueId = [NSNumber numberWithInt:sqlite3_column_int(statement, 0)];
            word.name = [[NSString alloc] initWithBytes:sqlite3_column_text(statement, 1) length:sqlite3_column_bytes(statement, 1) encoding:NSUTF8StringEncoding];
            word.languageCode =  [NSNumber numberWithInt:sqlite3_column_int(statement, 2)];
            const void *grammarInfoBytes = sqlite3_column_text(statement, 3);
            if (grammarInfoBytes) {
                word.grammarInfo = [[NSString alloc] initWithBytes:grammarInfoBytes length:sqlite3_column_bytes(statement, 3) encoding:NSUTF8StringEncoding];
            }
        }
        sqlite3_finalize(statement);
    }
    
    return word;
}

-(SQLiteWord *)randomWordWithLanguageCode:(NSNumber *)languageCode
{
    SQLiteWord *word = nil;
    
    int maxId = [self maxIdInWords];
    
    BOOL noMatch = YES;
    int randomId = arc4random_uniform(maxId-20);
    
    while (noMatch) {
        NSString *queryStatement = [NSString stringWithFormat:@"SELECT uniqueid, name, language, grammarInfo FROM words WHERE language = %i AND (uniqueid >= %i AND uniqueid <= %i) LIMIT 1", [languageCode intValue], randomId, randomId + 20];            
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [queryStatement UTF8String], -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                word = [[SQLiteWord alloc] init];
                word.uniqueId = [NSNumber numberWithInt:sqlite3_column_int(statement, 0)];
                word.name = [[NSString alloc] initWithBytes:sqlite3_column_text(statement, 1) length:sqlite3_column_bytes(statement, 1) encoding:NSUTF8StringEncoding];
                word.languageCode =  [NSNumber numberWithInt:sqlite3_column_int(statement, 2)];
                const void *grammarInfoBytes = sqlite3_column_text(statement, 3);
                if (grammarInfoBytes) {
                    word.grammarInfo = [[NSString alloc] initWithBytes:grammarInfoBytes length:sqlite3_column_bytes(statement, 3) encoding:NSUTF8StringEncoding];
                }
                noMatch = NO;
            }
            sqlite3_finalize(statement);
        }
    }
    
    return word;
}

//UniqueIds must be an array of NSNumbers
-(void)wordsByUniqueIds:(NSArray *)wordUniqueIds
             usingBlock:(db_query_wordsArray_completion_block_t)resultsBlock
{
    if (wordUniqueIds && [wordUniqueIds count] > 0) {
        dispatch_async(queryQueue, ^{
            NSMutableArray *results = [[NSMutableArray alloc] init];
            
            NSString *wordUniqueIdsString = @"";
            for (NSNumber *uniqueId in wordUniqueIds) {
                wordUniqueIdsString = [wordUniqueIdsString stringByAppendingFormat:@"%i,", [uniqueId intValue]];
            }
            wordUniqueIdsString = [wordUniqueIdsString substringToIndex:wordUniqueIdsString.length-1];
            
            NSString *queryStatement = [NSString stringWithFormat:@"SELECT uniqueid, name, language, grammarInfo FROM words WHERE uniqueid IN (%@)", wordUniqueIdsString];            
            sqlite3_stmt *statement;
            if (sqlite3_prepare_v2(database, [queryStatement UTF8String], -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    SQLiteWord *word = [[SQLiteWord alloc] init];
                    word.uniqueId = [NSNumber numberWithInt:sqlite3_column_int(statement, 0)];
                    word.name = [[NSString alloc] initWithBytes:sqlite3_column_text(statement, 1) length:sqlite3_column_bytes(statement, 1) encoding:NSUTF8StringEncoding];
                    word.languageCode =  [NSNumber numberWithInt:sqlite3_column_int(statement, 2)];
                    const void *grammarInfoBytes = sqlite3_column_text(statement, 3);
                    if (grammarInfoBytes) {
                        word.grammarInfo = [[NSString alloc] initWithBytes:grammarInfoBytes length:sqlite3_column_bytes(statement, 3) encoding:NSUTF8StringEncoding];
                    }
                    
                    [results addObject:word];
                }
                sqlite3_finalize(statement);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                resultsBlock(nil, results);
            });
            
        });
    } else {
        resultsBlock(nil, nil);
    }
}

-(void)recentsUsingBlock:(db_query_wordsArray_completion_block_t)resultsBlock
{
    NSArray *exercises = [[DictVocTrainer instance] recentExercises];

    if (exercises && [exercises count] > 0) {
        dispatch_async(queryQueue, ^{
            NSMutableArray *results = [[NSMutableArray alloc] init];
            
            NSString *wordUniqueIds = @"";
            for (Exercise *exercise in exercises) {
                wordUniqueIds = [wordUniqueIds stringByAppendingFormat:@"%i,", [exercise.wordUniqueId intValue]];
            }
            wordUniqueIds = [wordUniqueIds substringToIndex:wordUniqueIds.length-1];
            
            NSString *queryStatement = [NSString stringWithFormat:@"SELECT uniqueid, name, language, grammarInfo FROM words WHERE uniqueid IN (%@)", wordUniqueIds];            
            sqlite3_stmt *statement;
            if (sqlite3_prepare_v2(database, [queryStatement UTF8String], -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    SQLiteWord *word = [[SQLiteWord alloc] init];
                    word.uniqueId = [NSNumber numberWithInt:sqlite3_column_int(statement, 0)];
                    word.name = [[NSString alloc] initWithBytes:sqlite3_column_text(statement, 1) length:sqlite3_column_bytes(statement, 1) encoding:NSUTF8StringEncoding];
                    word.languageCode =  [NSNumber numberWithInt:sqlite3_column_int(statement, 2)];
                    const void *grammarInfoBytes = sqlite3_column_text(statement, 3);
                    if (grammarInfoBytes) {
                        word.grammarInfo = [[NSString alloc] initWithBytes:grammarInfoBytes length:sqlite3_column_bytes(statement, 3) encoding:NSUTF8StringEncoding];
                    }
                    
                    [results addObject:word];
                }
                sqlite3_finalize(statement);
            }
                 
            dispatch_async(dispatch_get_main_queue(), ^{
                resultsBlock(nil, results);
            });
                 
        });
    }
}


@end
