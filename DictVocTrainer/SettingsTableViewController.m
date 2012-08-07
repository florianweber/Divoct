/*
SettingsTableViewController.m
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


#import "SettingsTableViewController.h"
#import "GlobalDefinitions.h"
#import "FWToastView.h"
#import "Logging.h"
#import "DictVocTrainer.h"

@interface SettingsTableViewController () <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *caseSwitch;

@end

@implementation SettingsTableViewController

#pragma mark - My Messages

- (void)loadAndDisplaySettings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *searchModeKey = DVT_NSUSERDEFAULTS_SEARCHMODE;
    NSNumber *userDefaultsSearchMode = (NSNumber *)[defaults objectForKey:searchModeKey];
    if (userDefaultsSearchMode) {
        if ([userDefaultsSearchMode intValue] == DictionarySearchMode_TermBeginsWithCaseSensitive) {
            self.caseSwitch.on = NO;
        } else if ([userDefaultsSearchMode intValue] == DictionarySearchMode_TermBeginsWithCaseInsensitive) {
            self.caseSwitch.on = YES;
        }
    } else {
        switch (DVT_DEFAULTSEARCHMODE) {
            case DictionarySearchMode_TermBeginsWithCaseSensitive:
                self.caseSwitch.on = NO;
                break;
                
            case DictionarySearchMode_TermBeginsWithCaseInsensitive:
                self.caseSwitch.on = YES;
                break;
                
            default:
                self.caseSwitch.on = NO;
                break;
        }
        ;
    }
}

-(void)showHelp 
{
    [FWToastView toastInView:self.navigationController.view withText:NSLocalizedString(@"HELP_SETTINGS_MAIN", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
}

#pragma mark - Target / Action
@synthesize caseSwitch;

- (IBAction)searchCaseSwitchSwitched:(UISwitch *)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *searchModeKey = DVT_NSUSERDEFAULTS_SEARCHMODE;
    
    if (sender.on) {
        //set to case insensitive
        [defaults setObject:[NSNumber numberWithInt:DictionarySearchMode_TermBeginsWithCaseInsensitive] forKey:searchModeKey];
    } else {
        //set to case sensitive
        [defaults setObject:[NSNumber numberWithInt:DictionarySearchMode_TermBeginsWithCaseSensitive] forKey:searchModeKey];
    }
    
    [defaults synchronize];
    
    NSNotification *searchCaseSwitchedNotification = [NSNotification notificationWithName:DVT_SETTINGS_NOTIFICATION_SEARCHCASESWITCHED object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:searchCaseSwitchedNotification];
}


#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
    {
        LogDebug(@"Cancel Button was selected.");
    }
    else if (buttonIndex == 1)
    {
        LogDebug(@"Confirm Button was selected.");
        [[DictVocTrainer instance] resetAllExerciseStatistics];
        [[DictVocTrainer instance] deleteAllTrainingResults];
        
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SETTINGS_STATISTICS_RESET_CONFIRMATION_TITLE", nil)
                                                          message:NSLocalizedString(@"SETTINGS_STATISTICS_RESET_CONFIRMATION_MESSAGE", nil)
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"SETTINGS_STATISTICS_RESET_CONFIRMATION_BUTTON", nil)
                                                otherButtonTitles:nil];
        
        [message show];
    }
    else
    {
        LogDebug(@"Unknown Button was selected.");
    }
        
}

#pragma mark - View Lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadAndDisplaySettings];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}
- (void)viewDidUnload
{
    [self setCaseSwitch:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.section == 2) && (indexPath.row == 0)) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SETTINGS_STATISTICS_RESET_TITLE", nil)
                                                          message:NSLocalizedString(@"SETTINGS_STATISTICS_RESET_MESSAGE", nil)
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"SETTINGS_STATISTICS_RESET_CANCEL", nil)
                                                otherButtonTitles:NSLocalizedString(@"SETTINGS_STATISTICS_RESET_CONFIRM", nil), nil];
        
        [message show];

    }
}

@end
