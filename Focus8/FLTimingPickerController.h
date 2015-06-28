//
//  FLTimingPickerController.h
//  Focus8
//
//  Created by Sibin Baby on 25/06/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TimingPickerType) {
    TaskTimePicker,
    ShortBreakPicker,
    LongBreakPicker,
};

@class FLTimingPickerController;

@protocol FLTimingPickerDelegate <NSObject>
- (void)pickerController:(FLTimingPickerController *)controller didSelectValue:(NSTimeInterval)selectedTime forPicker:(TimingPickerType)picker;
@end

@interface FLTimingPickerController : UIViewController

@property (nonatomic, weak) id <FLTimingPickerDelegate> delegate;
@property (nonatomic, assign) TimingPickerType timingPickerType;
@property (nonatomic) NSTimeInterval sessionTime;
@end
