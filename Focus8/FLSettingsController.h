//
//  FLSettingsController.h
//  Focus8
//
//  Created by Sibin Baby on 27/08/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLSettingsController;

@protocol FLSettingsControllerDelegate <NSObject>

- (void)settingsController:(FLSettingsController *)controller didChangeAlarmSound:(NSString *)sound;

@end

@interface FLSettingsController : UITableViewController

@property (nonatomic, weak) id <FLSettingsControllerDelegate> delegate;
@property (nonatomic, strong) NSString *alarmSound;

@end
