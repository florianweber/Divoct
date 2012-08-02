/*
 GlobalDefinitions.h
 Divoct
 
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

#ifndef DictVocTrainer_GlobalDefinitions_h
#define DictVocTrainer_GlobalDefinitions_h

#define DVT_DB_FILE_NAME @"dvtDatabase.sqlite"
#define DVT_TRAINER_DB_FILE_NAME @"trainerDatabase.coredata"
#define DVT_NSUSERDEFAULTS_SEARCHMODE @"dvt_searchmode"
#define DVT_NSUSERDEFAULTS_TRAININGMODE @"dvt_trainingmode"
#define DVT_MAX_COLLECTION_NAME_LENGTH 30
#define DVT_MAX_COLLECTION_DESC_LENGTH 90
#define DVT_WAITSECONDS_FOR_USER_INPUT 0.3
#define DVT_WAITSECONDS_FOR_TRAINING_NEXT 1
#define DVT_BACKGROUND_FETCH_PRIORITY 0.3
#define DVT_STARTSEARCH_WITH_LENGTH 4
#define DVT_DEFAULTSEARCHMODE 1 //you also need to change the default button title in storyboard if you change this value
#define DVT_MAX_RESULTS_TO_SORT 5000
#define DVT_SETTINGS_NOTIFICATION_SEARCHCASESWITCHED @"SEARCH_CASE_SWITCHED"
#define DVT_COLLECTION_NOTIFICATION_RENAMED @"COLLECTION_RENAMED"
#define DVT_COLLECTION_NOTIFICATION_INSERTED @"COLLECTION_INSERTED"
#define DVT_COLLECTION_NOTIFICATION_DELETED @"COLLECTION_DELETED"
#define DVT_COLLECTION_NOTIFICATION_CONTENTS_CHANGED @"COLLECTION_CONTENTS_CHANGED"



#endif

typedef enum {
    DictionarySearchMode_TermBeginsWithCaseSensitive = 0,
    DictionarySearchMode_TermBeginsWithCaseInsensitive = 1
} DictionarySearchMode;

typedef enum {
    TrainingMode_Buttons = 0,
    TrainingMode_TextInput = 1
} TrainingMode;