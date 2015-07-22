//
//  FLSessionCountPickerController.m
//  Focus8
//
//  Created by Sibin Baby on 5/07/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import "FLSessionCountPickerController.h"
#import "UIColor+FlatColors.h"
#import "Focus8-Swift.h"

@interface FLSessionCountPickerController () <UIPickerViewDataSource, UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet DesignableView *popUpView;
@property (strong, nonatomic) NSArray *sessionCountArray;

@end

@implementation FLSessionCountPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    self.pickerView.delegate = self;
    
    self.sessionCountArray = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10, @11, @12, @13, @14, @15, @16, @17, @18, @19, @20, @21, @22, @23, @24, @25];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.selectedTaskSessionCount) {
        NSNumber *taskSessionCount = [NSNumber numberWithInteger:self.selectedTaskSessionCount];
        [self.pickerView selectRow:[self.sessionCountArray indexOfObject:taskSessionCount] inComponent:0 animated:YES];
        self.totalTimeLabel.text = [self stringifyTotalTime:(int)(self.selectedTaskSessionCount * self.selectedTaskSessionTime) usingLongFormat:YES];
    }
}

- (IBAction)save:(id)sender
{
    NSInteger selectedRow;
    selectedRow = [self.pickerView selectedRowInComponent:0];
    
    [self.delegate pickerController:self didSelectTargetTaskSessions:[self.sessionCountArray[selectedRow] integerValue]];
    [self dismissPopUp];
}

- (IBAction)cancel:(id)sender
{
    [self dismissPopUp];
}

- (void)dismissPopUp
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
    return [self.sessionCountArray count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [NSString stringWithFormat:@"%@ sessions", self.sessionCountArray[row]];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 32;
}

#pragma mark - Pickerview delegate methods.

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.totalTimeLabel.text = [self stringifyTotalTime:([self.sessionCountArray[row] intValue] * self.selectedTaskSessionTime) usingLongFormat:YES];
}

#pragma mark - StringifyTime method.

- (NSString *)stringifyTotalTime:(int)seconds usingLongFormat:(BOOL)longFormat
{
    int remainingSeconds = seconds;
    
    int hours = remainingSeconds / 3600;
    
    remainingSeconds = remainingSeconds - hours * 3600;
    
    int minutes = remainingSeconds / 60;
    
    remainingSeconds = remainingSeconds - minutes * 60;
    
    if (longFormat) {
        if (hours > 0) {
            return [NSString stringWithFormat:@"%iHr %iMin", hours, minutes];
        } else {
            return [NSString stringWithFormat:@"%iMin", minutes];
        }
    } else {
        if (hours > 0) {
            return [NSString stringWithFormat:@"%02i:%02i", hours, minutes];
        } else {
            return [NSString stringWithFormat:@"%02i", minutes];
        }
    }
}

@end
