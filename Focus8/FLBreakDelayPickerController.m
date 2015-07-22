//
//  FLBreakDelayPickerController.m
//  Focus8
//
//  Created by Sibin Baby on 4/07/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import "FLBreakDelayPickerController.h"
#import "UIColor+FlatColors.h"
#import "Focus8-Swift.h"

@interface FLBreakDelayPickerController () <UIPickerViewDelegate, UIPickerViewDataSource>
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet DesignableView *popUpView;
@property (nonatomic, strong) NSArray *delayListArray;

@end

@implementation FLBreakDelayPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    self.pickerView.delegate = self;
    
    self.delayListArray = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10, @11, @12, @13, @14, @15, @16, @17, @18, @19, @20, @21, @22, @23, @24, @25];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.selectedValue) {
        NSNumber *longBreakDelay = [NSNumber numberWithInteger:self.selectedValue];
        [self.pickerView selectRow:[self.delayListArray indexOfObject:longBreakDelay] inComponent:0 animated:YES];
    }
}

- (IBAction)cancel:(id)sender
{
    [self dismissPopUp];
}

- (IBAction)save:(id)sender
{
    NSInteger selectedRow;
    selectedRow = [self.pickerView selectedRowInComponent:0];
    [self.delegate pickerController:self didSelectDelay:[self.delayListArray[selectedRow] integerValue]];
    
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
    return [self.delayListArray count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [NSString stringWithFormat:@"after %@ sessions", self.delayListArray[row]];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 32;
}

#pragma mark - Pickerview delegate methods.

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.selectedValue = [self.delayListArray[row] integerValue];
}

@end
