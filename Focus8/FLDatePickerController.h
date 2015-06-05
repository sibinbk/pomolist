//
//  FLDatePickerController.h
//  Focus8
//
//  Created by Sibin Baby on 27/05/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class FLDatePickerController;

@protocol FLDatePickerControllerDelegate <NSObject>

- (void)pickerController:(FLDatePickerController *)controller reminderAdded:(NSDate *)reminderDate;
- (void)pickerController:(FLDatePickerController *)controller reminderRemoved:(BOOL)removed;

@end

@interface FLDatePickerController : UIViewController

@property (nonatomic, weak) id <FLDatePickerControllerDelegate> delegate;
@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) NSDate *reminderDate;

- (void)showDatePickerOnView:(UIView *)aView animated:(BOOL)animated;

@end
