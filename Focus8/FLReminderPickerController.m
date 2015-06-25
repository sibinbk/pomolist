//
//  FLReminderPickerController.m
//  Focus8
//
//  Created by Sibin Baby on 22/06/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import "FLReminderPickerController.h"
#import "UIColor+FlatColors.h"
#import "Focus8-Swift.h"

@interface FLReminderPickerController ()
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UILabel *pickerTitle;
@property (weak, nonatomic) IBOutlet DesignableView *popUpView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pickerWidthConstraint;

@end

@implementation FLReminderPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    
    //Chcek Screen size to resize the picker width accordingly.
    
    self.pickerWidthConstraint.constant = ([UIScreen mainScreen].bounds.size.width > 320.0) ? 320 : 310;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    // Set PickerDate to reminder date if available.
    
    if (!self.reminderDate) {
        [self.datePicker setDate:[NSDate date]];
    } else {
        [self.datePicker setDate:self.reminderDate];
    }
}
- (IBAction)saveReminder:(id)sender
{
    [self.delegate pickerController:self reminderSetOn:self.datePicker.date];
    [self dismissReminderPicker];
}

- (IBAction)removeReminder:(id)sender
{
    [self.delegate pickerController:self reminderRemoved:YES];
    [self dismissReminderPicker];
}

- (void)dismissReminderPicker
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

@end
