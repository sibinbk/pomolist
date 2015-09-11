//
//  FLTimingPickerController.m
//  Focus8
//
//  Created by Sibin Baby on 25/06/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import "FLTimingPickerController.h"
#import "Focus8-Swift.h"

@interface FLTimingPickerController () <UIPickerViewDataSource, UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet DesignableView *popUpView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) NSArray *timeListArray;
@property (nonatomic, strong) NSArray *taskSessionArray;
@property (nonatomic, strong) NSArray *shortBreakArray;
@property (nonatomic, strong) NSArray *LongBreakArray;
@end

@implementation FLTimingPickerController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    self.pickerView.delegate = self;
    
    self.taskSessionArray = @[@60, @120, @180, @240, @300, @360, @420, @480, @540, @600, @660, @720, @780, @840, @900, @960, @1020, @1080, @1140, @1200,
                              @1260, @1320, @1380, @1440, @1500, @1560, @1620, @1680, @1740, @1800, @1860, @1920, @1980, @2040, @2100, @2160, @2220, @2280, @2340, @2400,
                              @2460, @2520, @2580, @2640, @2700, @2760, @2820, @2880, @2940, @3000, @3060, @3120, @3180, @3240, @3300, @3360, @3420, @3480, @3540, @3600];
    self.shortBreakArray = @[@15, @30, @60, @120, @180, @240, @300, @360, @420, @480, @540, @600, @660, @720, @780, @840, @900, @960, @1020, @1080, @1140, @1200,
                             @1260, @1320, @1380, @1440, @1500, @1560, @1620, @1680, @1740, @1800, @1860, @1920, @1980, @2040, @2100, @2160, @2220, @2280, @2340, @2400,
                             @2460, @2520, @2580, @2640, @2700, @2760, @2820, @2880, @2940, @3000, @3060, @3120, @3180, @3240, @3300, @3360, @3420, @3480, @3540, @3600];
    self.LongBreakArray = @[@60, @120, @180, @240, @300, @360, @420, @480, @540, @600, @660, @720, @780, @840, @900, @960, @1020, @1080, @1140, @1200,
                            @1260, @1320, @1380, @1440, @1500, @1560, @1620, @1680, @1740, @1800, @1860, @1920, @1980, @2040, @2100, @2160, @2220, @2280, @2340, @2400,
                            @2460, @2520, @2580, @2640, @2700, @2760, @2820, @2880, @2940, @3000, @3060, @3120, @3180, @3240, @3300, @3360, @3420, @3480, @3540, @3600, @5400];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    switch (self.timingPickerType) {
        case TaskTimePicker:
            self.titleLabel.text = @"Pomodoro";
            self.timeListArray = self.taskSessionArray;
            break;
        case ShortBreakPicker:
            self.titleLabel.text = @"Short Break";
            self.timeListArray = self.shortBreakArray;
            break;
        case LongBreakPicker:
            self.titleLabel.text = @"Long Break";
            self.timeListArray = self.LongBreakArray;
            break;
        default:
            break;
    }
    
    if (self.sessionTime != 0) {
        NSNumber *selectedTime = [NSNumber numberWithInteger:self.sessionTime];
        [self.pickerView selectRow:[self.timeListArray indexOfObject:selectedTime] inComponent:0 animated:YES];
    }
}

- (IBAction)cancelPopUp:(id)sender
{
    [self dismissTimingPicker];
}

- (IBAction)selectTiming:(id)sender
{
    NSInteger selectedRow = [self.pickerView selectedRowInComponent:0];
    
    self.sessionTime = [self.timeListArray[selectedRow] integerValue];
    
    // Timing picker delegate.
    [self.delegate pickerController:self didSelectValue:self.sessionTime forPicker:self.timingPickerType];
    
    [self dismissTimingPicker];
}

- (void)dismissTimingPicker
{
    self.popUpView.animation=@"fall";
    self.popUpView.duration = 1.5;
    [self.popUpView animate];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

#pragma mark - Pickerview data source methods.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.timeListArray count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *timingString;
    
    if ([self.timeListArray[row] intValue] < 60) {
        timingString = [NSString stringWithFormat:@"%i seconds", [self.timeListArray[row] intValue]];
    } else if ([self.timeListArray[row] intValue] == 60){
        timingString = [NSString stringWithFormat:@"%i minute", [self.timeListArray[row] intValue] / 60];
    } else {
        timingString = [NSString stringWithFormat:@"%i minutes", [self.timeListArray[row] intValue] / 60];
    }
    
    return timingString;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 36;
}

@end
