//
//  FLPopUpPickerController.h
//  Focus8
//
//  Created by Sibin Baby on 4/06/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PopUpPickerType) {
    TaskTimePicker = 0,
    ShortBreakPicker,
    LongBreakPicker,
    LongBreakDelayPicker
};

@class FLPopUpPickerController;

@protocol FLPopUpPickerControllerDelegate <NSObject>

- (void)pickerController:(FLPopUpPickerController *)controller didSelectValue:(NSString *)value forPicker:(PopUpPickerType)picker;

@end

@interface FLPopUpPickerController : UIViewController

@property (nonatomic, weak) id <FLPopUpPickerControllerDelegate> delegate;
@property (strong, nonatomic) NSArray *tableArray;
@property (strong, nonatomic) NSString *selectedValue;
@property (strong, nonatomic) NSString *pickerTitle;
@property (nonatomic, strong) UIColor *titleColor;
@property (assign, nonatomic) PopUpPickerType pickerType;

- (void)showPopUpPicker:(UIView *)aView animated:(BOOL)animated;
@end
