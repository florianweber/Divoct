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
#import "DictVocSettings.h"

@interface SettingsTableViewController () <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *caseSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *trainingAutocorrectionSwitch;

@end

@implementation SettingsTableViewController

#pragma mark - My Messages

- (void)loadAndDisplaySettings
{
    //searchMode
    int searchMode = [DictVocSettings instance].searchMode;
    if (searchMode == DictionarySearchMode_TermBeginsWithCaseSensitive) {
        self.caseSwitch.on = NO;
    } else if (searchMode == DictionarySearchMode_TermBeginsWithCaseInsensitive) {
        self.caseSwitch.on = YES;
    }
    
    //Training Autocorrection
    self.trainingAutocorrectionSwitch.on = [DictVocSettings instance].trainingTextInputAutoCorrection;
}

-(void)showHelp 
{
    [FWToastView toastInView:self.navigationController.view withText:NSLocalizedString(@"HELP_SETTINGS_MAIN", nil) icon:FWToastViewIconInfo duration:FWToastViewDurationUnlimited withCloseButton:YES];
}

#pragma mark - Target / Action
@synthesize caseSwitch;

- (IBAction)searchCaseSwitchSwitched:(UISwitch *)sender {
    
    if (sender.on) {
        //set to case insensitive
        [DictVocSettings instance].searchMode = DictionarySearchMode_TermBeginsWithCaseInsensitive;
    } else {
        //set to case sensitive
        [DictVocSettings instance].searchMode = DictionarySearchMode_TermBeginsWithCaseSensitive;
    }
}

- (IBAction)trainingAutocorrectionSwitchValueChanged:(UISwitch *)sender {
    [DictVocSettings instance].trainingTextInputAutoCorrection = sender.on;
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
    [self setTrainingAutocorrectionSwitch:nil];
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
    if ((indexPath.section == 1) && (indexPath.row == 2)) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SETTINGS_STATISTICS_RESET_TITLE", nil)
                                                          message:NSLocalizedString(@"SETTINGS_STATISTICS_RESET_MESSAGE", nil)
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"SETTINGS_STATISTICS_RESET_CANCEL", nil)
                                                otherButtonTitles:NSLocalizedString(@"SETTINGS_STATISTICS_RESET_CONFIRM", nil), nil];
        
        [message show];

    }
}

@end
