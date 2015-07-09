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
@property (weak, nonatomic) IBOutlet UILabel *sessionCountLabel;
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
    self.sessionCountLabel.text = [NSString stringWithFormat:@"%@ sessions", self.sessionCountArray[row]];
//    self.totalTimeLabel.text = [NSString stringWithFormat:@"%ld", (long) self.taskSessionTime * [self.sessionCountArray[row] integerValue]];
}
@end
