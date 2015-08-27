//
//  FLSettingsController.m
//  Focus8
//
//  Created by Sibin Baby on 27/08/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import "FLSettingsController.h"

static NSString * const kFLScreenLockUserDefaultsKey = @"kFLScreenLockUserDefaultsKey";

@interface FLSettingsController ()

@property (weak, nonatomic) IBOutlet UILabel *alarmSoundLabel;
@property (weak, nonatomic) IBOutlet UISwitch *muteOnSwich;
@property (weak, nonatomic) IBOutlet UISwitch *vibrateOnSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *preventScreenLockSwitch;

@end

@implementation FLSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Check if Screen Lock Timer is disabled.
    self.preventScreenLockSwitch.on = [UIApplication sharedApplication].idleTimerDisabled;
}

- (IBAction)muteAllSound:(id)sender
{
}

- (IBAction)vibrateOnSilentMode:(id)sender
{
}

- (IBAction)preventScreenLock:(id)sender
{
    // Disable idle timer to prevent screen lock while app is on foreground.
    [[UIApplication sharedApplication] setIdleTimerDisabled:self.preventScreenLockSwitch.isOn];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSNumber numberWithBool:self.preventScreenLockSwitch.isOn] forKey:kFLScreenLockUserDefaultsKey];
    
    [userDefaults synchronize];
}

- (IBAction)exitSettings:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
