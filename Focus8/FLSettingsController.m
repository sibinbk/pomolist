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

static NSString * const kFLScreenLockUserDefaultsKey = @"kFLScreenLockUserDefaultsKey";
static NSString * const kFLAlarmSoundUserDefaultsKey = @"kFLAlarmSoundUserDefaultsKey";

@interface FLSettingsController () <FLSoundPickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *alarmSoundLabel;
@property (weak, nonatomic) IBOutlet UISwitch *muteSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *preventScreenLockSwitch;

@end

@implementation FLSettingsController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Check if Mute is On.
    self.muteSwitch.on = [JSQSystemSoundPlayer sharedPlayer].on;
    
    // Check if Screen Lock Timer is disabled.
    self.preventScreenLockSwitch.on = [UIApplication sharedApplication].idleTimerDisabled;
}

- (IBAction)muteAllSound:(UISwitch *)sender
{
    [[JSQSystemSoundPlayer sharedPlayer] toggleSoundPlayerOn:sender.on];
}

- (IBAction)preventScreenLock:(UISwitch *)sender
{
    // Disable idle timer to prevent screen lock while app is on foreground.
    [[UIApplication sharedApplication] setIdleTimerDisabled:self.preventScreenLockSwitch.isOn];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSNumber numberWithBool:self.preventScreenLockSwitch.isOn] forKey:kFLScreenLockUserDefaultsKey];
    
    [userDefaults synchronize];
}

#pragma mark - Settings controller exit method.

- (IBAction)exitSettings:(id)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.alarmSound forKey:kFLAlarmSoundUserDefaultsKey];
    [userDefaults synchronize];
    
    [self dismissViewControllerAnimated:YES completion:nil];
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

@end
