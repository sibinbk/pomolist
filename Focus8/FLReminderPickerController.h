//
//  FLReminderPickerController.h
//  Focus8
//
//  Created by Sibin Baby on 22/06/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLReminderPickerController;

@protocol FLReminderPickerDelegate <NSObject>

- (void)pickerController:(FLReminderPickerController *)controller reminderSetOn:(NSDate *)reminderDate;
- (void)pickerController:(FLReminderPickerController *)controller reminderRemoved:(BOOL)removed;

@end

@interface FLReminderPickerController : UIViewController

@property (nonatomic, weak) id <FLReminderPickerDelegate> delegate;
@property (nonatomic, strong) NSDate *reminderDate;

@end
