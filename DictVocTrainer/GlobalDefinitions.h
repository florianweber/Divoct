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
#define DVT_TRAINER_DB_IMPORT_FILE_NAME @"persistentStore"
#define DVT_NSUSERDEFAULTS_SEARCHMODE_KEY @"dvt_searchMode"
#define DVT_NSUSERDEFAULTS_TRAININGMODE_KEY @"dvt_trainingMode"
#define DVT_NSUSERDEFAULTS_WRONGANSWERHANDLINGMODE_KEY @"dvt_wrongAnswerHandlingMode"
#define DVT_NSUSERDEFAULTS_WARN_WELLKNOWN_ONLY_KEY @"dvt_warnWellKnownOnly"
#define DVT_NSUSERDEFAULTS_PERFECT_SUCCESSRATE_SETTING_KEY @"dvt_perfectSuccessrateSetting"
#define DVT_NSUSERDEFAULTS_TRAINING_TEXTINPUT_AUTOCORRECTION_KEY @"dvt_trainingTextInputAutoCorrection"
#define DVT_MAX_COLLECTION_NAME_LENGTH 30
#define DVT_MAX_COLLECTION_DESC_LENGTH 90
#define DVT_WAITSECONDS_FOR_USER_INPUT 0.3
#define DVT_WAITSECONDS_FOR_TRAINING_NEXT 1
#define DVT_WAITSECONDS_FOR_TRAINING_NEXT_IF_WRONG 3
#define DVT_BACKGROUND_FETCH_PRIORITY 0.3
#define DVT_STARTSEARCH_WITH_LENGTH 4
#define DVT_DEFAULTSEARCHMODE 1 //you also need to change the default button title in storyboard if you change this value
#define DVT_DEFAULT_TRAINING_ANSWER_INPUT_MODE 0
#define DVT_DEFAULT_TRAINING_WRONG_ANSWER_HANDLING_MODE 0
#define DVT_DEFAULT_PERFECT_SUCCESSRATE 2
#define DVT_DEFAULT_WARN_WELLKNOWN_ONLY YES
#define DVT_DEFAULT_TEXTINPUT_AUTOCORRECTION NO
#define DVT_MAX_RESULTS_TO_SORT 5000
#define DVT_MIN_WORDLENGTH_CORRECT_PERCENTAGE 0.7
#define DVT_SETTINGS_NOTIFICATION_SEARCHCASESWITCHED @"SEARCH_CASE_SWITCHED"
#define DVT_SETTINGS_NOTIFICATION_TRAINING_TEXTINPUT_AUTOCORRECTION_CHANGED @"TXTIN_AUTOCORRECTION_CHANGED"

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
    TrainingAnswerInputMode_MultipleChoice = 0,
    TrainingAnswerInputMode_TextInput = 1
} TrainingAnswerInputMode;

typedef enum {
    TrainingWrongAnswerHandlingMode_Repeat = 0,
    TrainingWrongAnswerHandlingMode_Dismiss = 1
} TrainingWrongAnswerHandlingMode;