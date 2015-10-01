//
//  FLSettingsController.m
//  Focus8
//
//  Created by Sibin Baby on 27/08/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import "FLSettingsController.h"
#import "JSQSystemSoundPlayer.h"
#import "FLSoundPickerController.h"
#import <Social/Social.h>

static NSString * const kFLScreenLockKey = @"kFLScreenLockKey";
static NSString * const kFLAlarmSoundKey = @"kFLAlarmSoundKey";

@interface FLSettingsController () <FLSoundPickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *alarmSoundLabel;
@property (weak, nonatomic) IBOutlet UISwitch *preventScreenLockSwitch;

@end

@implementation FLSettingsController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.alarmSoundLabel.text = self.alarmSound;
    
    // Check if Screen Lock Timer is disabled.
    self.preventScreenLockSwitch.on = [UIApplication sharedApplication].idleTimerDisabled;
}

- (IBAction)preventScreenLock:(UISwitch *)sender
{
    // Disable idle timer to prevent screen lock while app is on foreground.
    [[UIApplication sharedApplication] setIdleTimerDisabled:self.preventScreenLockSwitch.isOn];
    
    // Save Screenlock prevent switch status.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSNumber numberWithBool:self.preventScreenLockSwitch.isOn] forKey:kFLScreenLockKey];
    [userDefaults synchronize];
}

#pragma mark - Settings controller exit method.

- (IBAction)exitSettings:(id)sender
{
    // Save Alarm sound name.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.alarmSound forKey:kFLAlarmSoundKey];
    [userDefaults synchronize];
    
    // Call delegate to inform alarm sound changed.
    [self.delegate settingsController:self didChangeAlarmSound:self.alarmSound];
}

#pragma mark - Sound picker delegate method.

-(void)soundPickerController:(FLSoundPickerController *)controller didSelectSound:(NSString *)sound
{
    NSLog(@"delegate");
    self.alarmSoundLabel.text = sound;
    self.alarmSound = sound;
}

#pragma mark - Segue methods.

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"soundPickerSegue"]) {
        FLSoundPickerController *soundPickerController = segue.destinationViewController;
        soundPickerController.delegate = self;
        soundPickerController.selectedSound = self.alarmSound;
    }
}

#pragma mark - Social sharing methods.

- (void)shareItOnfacebook
{
    // Facebook
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *fbPost = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [fbPost setInitialText:@"ABCD"];
        [fbPost addURL:[NSURL URLWithString:@"https://itunes.apple.com/app/abcd-alphabet-with-phonics/id527097956?mt=8"]];
        [fbPost setCompletionHandler:^(SLComposeViewControllerResult result)
         {
             if (result == SLComposeViewControllerResultCancelled)
             {
                 NSLog(@"The user cancelled.");
             }
             else if (result == SLComposeViewControllerResultDone)
             {
                 NSLog(@"The user sent the post.");
             }
         }];
        [self presentViewController:fbPost animated:YES completion:nil];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Can't share it!!"
                                                                       message:@"You are not logged in to your Facebook account.  Please login in to you Facebook account first."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                              }];
        [alert addAction:dismissAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)shareItOnTwitter
{
    // Twitter
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweet setInitialText:@"ABCD App"];
        [tweet addURL:[NSURL URLWithString:@"https://itunes.apple.com/app/abcd-alphabet-with-phonics/id527097956?mt=8"]];
        [tweet setCompletionHandler:^(SLComposeViewControllerResult result) {
            if (result == SLComposeViewControllerResultCancelled)
             {
                 NSLog(@"The user cancelled.");
             }
             else if (result == SLComposeViewControllerResultDone)
             {
                 NSLog(@"The user sent the tweet");
             }
         }];
        
        [self presentViewController:tweet animated:YES completion:nil];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Can't tweet it!!"
                                                                       message:@"You are not logged in to your Twitter account. Please login in to you Twitter account first."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                               }];
        [alert addAction:dismissAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2) {
        
        switch (indexPath.row) {
            case 0:
                [self shareItOnfacebook];
                break;
            case 1:
                [self shareItOnTwitter];
            default:
                break;
        }
    }
}
@end
