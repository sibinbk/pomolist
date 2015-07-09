//
//  FLTimingPickerController.m
//  Focus8
//
//  Created by Sibin Baby on 25/06/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import "FLTimingPickerController.h"
#import "UIColor+FlatColors.h"
#import "Focus8-Swift.h"

@interface FLTimingPickerController () <UIPickerViewDataSource, UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet DesignableView *popUpView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) NSArray *timeListArray;
@end

@implementation FLTimingPickerController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"Timing Picker View loaded");
    
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    self.pickerView.delegate = self;
    
    self.timeListArray = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10, @11, @12, @13, @14, @15, @16, @17, @18, @19, @20, @21, @22, @23, @24, @25, @26, @27, @28, @29, @30];
/*    self.timeListArray = @[@"1 minute",
                           @"2 minutes",
                           @"3 minutes",
                           @"4 minutes",
                           @"5 minutes",
                           @"6 minutes",
                           @"7 minutes",
                           @"8 minutes",
                           @"9 minutes",
                           @"10 minutes",
                           @"11 minutes",
                           @"12 minutes",
                           @"13 minutes",
                           @"14 minutes",
                           @"15 minutes",
                           @"16 minutes",
                           @"17 minutes",
                           @"18 minutes",
                           @"19 minutes",
                           @"20 minutes"];
 */
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // Set picker selected value to previosly selected Session time.
    NSLog(@"Session time : %f", self.sessionTime);
    if (self.sessionTime) {
        NSNumber *selectedIndex = [NSNumber numberWithInteger:self.sessionTime];
        [self.pickerView selectRow:[self.timeListArray indexOfObject:selectedIndex] inComponent:0 animated:YES];
    }
    
    switch (self.timingPickerType) {
        case TaskTimePicker:
            self.titleLabel.text = @"Task Session";
            break;
        case ShortBreakPicker:
            self.titleLabel.text = @"Short Break";
            break;
        case LongBreakPicker:
            self.titleLabel.text = @"Long Break";
            break;
        default:
            break;
    }
}

- (IBAction)cancelPopUp:(id)sender
{
    [self dismissTimingPicker];
}

- (IBAction)selectTiming:(id)sender
{
    NSInteger selectedRow;
    selectedRow = [self.pickerView selectedRowInComponent:0];
    
    [self.delegate pickerController:self didSelectValue:[self.timeListArray[selectedRow] integerValue] forPicker:self.timingPickerType];
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
    
    //    [self dismissViewControllerAnimated:YES completion:nil];
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
    return [NSString stringWithFormat:@"%@ minutes", self.timeListArray[row]];
//    return self.timeListArray[row];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 32;
}

#pragma mark - Pickerview delegate methods.

//- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
//{
//    self.sessionTime = [self.timeListArray[row] doubleValue] * 60;
//}

@end
