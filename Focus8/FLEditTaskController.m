//
//  FLEditTaskController.m
//  Focus8
//
//  Created by Sibin Baby on 12/11/2014.
//  Copyright (c) 2014 FocusApps. All rights reserved.
//

#import "FLEditTaskController.h"
#import "AppDelegate.h"
#import "Task.h"
#import "FLColorPicker.h"
#import "FLReminderPickerController.h"
#import "FLTimingPickerController.h"
#import "UIColor+FlatColors.h"
#import "Focus8-Swift.h"

#define kTaskTimePicker          @"taskTimePicker"
#define kShortBreakPicker        @"shortBreakPicker"
#define kLongBreakPicker         @"longBreakPicker"
#define kLongBreakDelayPicker    @"longBreakDelayPicker"
#define kRepeatCountPicker       @"repeatCountPicker"
#define kTaskColorPicker         @"taskColorPicker"
#define kShortBreakColorPicker   @"shortBreakColorPicker"
#define kLongBreakColorPicker    @"longBreakColorPicker"

@interface FLEditTaskController () <UITextFieldDelegate, FLReminderPickerDelegate, FLTimingPickerDelegate, FLColorPickerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSArray *taskTimeArray;
@property (strong, nonatomic) NSArray *shortBreakArray;
@property (strong, nonatomic) NSArray *longBreakArray;
@property (strong, nonatomic) NSArray *repeatCountArray;
@property (strong, nonatomic) NSArray *longBreakDelayArray;

@property (weak, nonatomic) IBOutlet UITextField *taskNameField;
@property (weak, nonatomic) IBOutlet UILabel *reminderTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *reminderDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *taskTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *shortBreakLabel;
@property (weak, nonatomic) IBOutlet UILabel *longBreakLabel;
@property (weak, nonatomic) IBOutlet UILabel *longBreakDelayLabel;
@property (weak, nonatomic) IBOutlet UILabel *repeatCountLabel;
@property (weak, nonatomic) IBOutlet DesignableView *taskColorView;
@property (weak, nonatomic) IBOutlet DesignableView *shortBreakColorView;
@property (weak, nonatomic) IBOutlet DesignableView *longBreakColorView;

@property (assign, nonatomic) TimingPickerType timingPickerType;

@property (strong, nonatomic) NSString *taskName;
@property (nonatomic) NSTimeInterval taskTime;
@property (nonatomic) NSTimeInterval shortBreakTime;
@property (nonatomic) NSTimeInterval longBreakTime;
@property (nonatomic) NSTimeInterval totalCountDownTime;
@property (nonatomic) NSInteger repeatCount;
@property (nonatomic) NSInteger longBreakDelay;
@property (strong, nonatomic) UIColor *taskColor;
@property (strong, nonatomic) UIColor *shortBreakColor;
@property (strong, nonatomic) UIColor *longBreakColor;
@property (strong, nonatomic) NSDate *reminderDate;
@property (strong, nonatomic) NSDateFormatter *formatter;

@property (strong, nonatomic) NSArray *colors;

@property (assign, nonatomic, getter = isNameTaken) BOOL nameTaken;
@property (strong, nonatomic) NSString *oldName;

@end

@implementation FLEditTaskController

- (NSManagedObjectContext *)managedObjectContext
{
    return [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
}

- (void)viewDidLoad
{
    NSLog(@"View did load");
    [super viewDidLoad];
    
    self.oldName = nil;
    
    //Setup date formatter
    self.formatter = [[NSDateFormatter alloc] init];
    NSString *format = [NSDateFormatter dateFormatFromTemplate:@"MMM d, yyyy hh:mm a" options:0 locale:[NSLocale currentLocale]];
    [self.formatter setDateFormat:format];
    
    self.colors = @[
                    [UIColor flatTurquoiseColor],
                    [UIColor flatGreenSeaColor],
                    [UIColor flatEmeraldColor],
                    [UIColor flatNephritisColor],
                    [UIColor flatPeterRiverColor],
                    [UIColor flatBelizeHoleColor],
                    [UIColor flatAmethystColor],
                    [UIColor flatWisteriaColor],
                    [UIColor flatSunFlowerColor],
                    [UIColor flatOrangeColor],
                    [UIColor flatCarrotColor],
                    [UIColor flatPumpkinColor],
                    [UIColor flatAlizarinColor],
                    [UIColor flatPomegranateColor],
                    [UIColor flatWetAsphaltColor],
                    [UIColor flatMidnightBlueColor]
                    ];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *contentDict = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PickerData" ofType:@"plist"]];
        self.taskTimeArray = [contentDict objectForKey:@"TaskTime"];
        self.shortBreakArray = [contentDict objectForKey:@"ShortBreakTime"];
        self.longBreakArray = [contentDict objectForKey:@"LongBreakTime"];
        self.longBreakDelayArray = [contentDict objectForKey:@"LongBreakDelay"];
        self.repeatCountArray = [contentDict objectForKey:@"RepeatCount"];
    });

    if ([self isTaskEditing]) {
        self.oldName = self.task.name;
        self.taskNameField.text = self.task.name;
        if (self.task.reminderDate != nil) {
            self.reminderTitleLabel.text = @"Remind on";
            self.reminderDateLabel.text = [self.formatter stringFromDate:self.task.reminderDate];
        }
        self.taskTimeLabel.text = [NSString stringWithFormat:@"%@ minutes", self.task.taskTime];
        self.shortBreakLabel.text = [NSString stringWithFormat:@"%@ minutes", self.task.shortBreakTime];
        self.longBreakLabel.text = [NSString stringWithFormat:@"%@ minutes", self.task.longBreakTime];
        self.longBreakDelayLabel.text = [NSString stringWithFormat:@"%@ tasks", self.task.longBreakDelay];
        self.repeatCountLabel.text = [NSString stringWithFormat:@"%@ times", self.task.repeatCount];
        
        self.reminderDate = self.task.reminderDate;
        self.taskTime = [self.task.taskTime doubleValue];
        self.shortBreakTime = [self.task.shortBreakTime doubleValue];
        self.longBreakTime = [self.task.longBreakTime doubleValue];
        self.taskColor = self.task.taskColor;
        self.shortBreakColor = self.task.shortBreakColor;
        self.longBreakColor = self.task.longBreakColor;
        
    } else {
        
        self.taskTime = 1800; // Task session 30 mins.
        self.shortBreakTime = 300; // Short break 5 mins.
        self.longBreakTime = 900; // Long break 15 mins.

        NSUInteger randomIndex = arc4random_uniform(13);
        
        self.taskColor = self.colors[randomIndex];
        self.shortBreakColor = [UIColor flatWetAsphaltColor];
        self.longBreakColor = [UIColor flatMidnightBlueColor];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    self.taskColorView.backgroundColor = self.taskColor;
    self.shortBreakColorView.backgroundColor = self.shortBreakColor;
    self.longBreakColorView.backgroundColor = self.longBreakColor;
}

#pragma mark - Save/ Cancel Methods

- (IBAction)cancel:(UIBarButtonItem *)sender
{
    [self.managedObjectContext rollback];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)save:(UIBarButtonItem *)sender
{
    if (self.isNameTaken) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Attention!", @"Attention!")
                                                        message:NSLocalizedString(@"Task name exists, Please enter another name", @"Task name exists, Please enter another name")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                              otherButtonTitles:nil];
        [alert show];
        
    } else {
        
        if (self.task == nil) {
            self.task = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:[self managedObjectContext]];
        }
        
        self.task.name = self.taskNameField.text;
        self.task.reminderDate = self.reminderDate;
        self.task.taskTime = [NSNumber numberWithInteger: [self.taskTimeLabel.text integerValue]];
        self.task.shortBreakTime = [NSNumber numberWithInteger: [self.shortBreakLabel.text integerValue]];
        self.task.longBreakTime = [NSNumber numberWithInteger:[self.longBreakLabel.text integerValue]];
        self.task.longBreakDelay = [NSNumber numberWithInteger:[self.longBreakDelayLabel.text integerValue]];
        self.task.repeatCount = [NSNumber numberWithInteger: [self.repeatCountLabel.text integerValue]];
        self.task.taskColor = self.taskColor;
        self.task.shortBreakColor = self.shortBreakColor;
        self.task.longBreakColor = self.longBreakColor;
        [self saveAndDismiss];
    }
}

- (void)saveAndDismiss
{
    NSError *error = nil;
    if ([self.managedObjectContext hasChanges]) {
        if (![self.managedObjectContext save:&error]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                            message:NSLocalizedString(@"Error in saving new task", @"Error in saving new task")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                                  otherButtonTitles:nil];
            [alert show];
            
        } else {
            if ([self.task.isSelected boolValue]) {
                NSLog(@"delegate method called");
                [self.delegate taskController:self didChangeTask:self.task withTimerValue:YES];
            }
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - tableview delegate method

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!(indexPath.section == 0 && indexPath.row == 0)) {
        [self.taskNameField resignFirstResponder];
    }
    
    if (indexPath.section == 1 && indexPath.row == 0) {
        [self performSegueWithIdentifier:@"reminderPickerSegue" sender:nil];
    }
    
    if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0:
                self.timingPickerType = TaskTimePicker;
                break;
            case 1:
                self.timingPickerType = ShortBreakPicker;
                break;
            case 2:
                self.timingPickerType = LongBreakPicker;
                break;
        }
        
        NSLog(@"Selected Row %ld",(long)indexPath.row);
        [self performSegueWithIdentifier:@"timingPickerSegue" sender:nil];
    }
    
    NSString *pickerType;
    
    if (indexPath.section == 3) {
        switch (indexPath.row) {
            case 0:
                pickerType = kTaskColorPicker;
                break;
            case 1:
                pickerType = kShortBreakColorPicker;
                break;
            case 2:
                pickerType = kLongBreakColorPicker;
                break;
            default:
                break;
        }
        
        [self performSegueWithIdentifier:@"colorPickerSegue" sender:pickerType];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"reminderPickerSegue"]) {
        FLReminderPickerController *reminderPicker = segue.destinationViewController;
        reminderPicker.reminderDate = self.reminderDate;
        reminderPicker.delegate = self;
    }
    
    if ([segue.identifier isEqualToString:@"timingPickerSegue"]) {
        FLTimingPickerController *timingPicker = segue.destinationViewController;
        timingPicker.delegate = self;
        
        switch (self.timingPickerType) {
            case TaskTimePicker:
                timingPicker.sessionTime = self.taskTime;
                timingPicker.timingPickerType = TaskTimePicker;
                break;
            case ShortBreakPicker:
                timingPicker.sessionTime = self.shortBreakTime;
                timingPicker.timingPickerType = ShortBreakPicker;
                break;
            case LongBreakPicker:
                timingPicker.sessionTime = self.longBreakTime;
                timingPicker.timingPickerType = LongBreakPicker;
                break;
        }
    }
    
    if ([segue.identifier isEqualToString:@"colorPickerSegue"]) {
        FLColorPicker *colorPicker = segue.destinationViewController;
        colorPicker.selectedPicker = sender;
        colorPicker.delegate = self;
        
        if ([sender isEqualToString:kTaskColorPicker]) {
            colorPicker.selectedColor = self.taskColor;
            colorPicker.navigationItem.title = @"Task Cycle";
        } else if ([sender isEqualToString:kShortBreakColorPicker]) {
            colorPicker.selectedColor = self.shortBreakColor;
            colorPicker.navigationItem.title = @"Short Break";
        } else if ([sender isEqualToString:kLongBreakColorPicker]) {
            colorPicker.selectedColor = self.longBreakColor;
            colorPicker.navigationItem.title = @"Long Break";
        }
    }
}

- (BOOL)isNameTaken
{
    if ([self.oldName isEqualToString:self.taskNameField.text]) {
        return NO;
    }
    
    // Creating a fetch request to check whether the name of the Task already exists
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    request.predicate = [NSPredicate predicateWithFormat:@"name == %@", self.taskNameField.text];
    
    NSError *error = nil;
    NSArray *tasks = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if ([tasks count] == 0) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - FLDatePickerController delegate methods.

- (void)pickerController:(FLReminderPickerController *)controller reminderSetOn:(NSDate *)reminderDate
{
    self.reminderDate = reminderDate;
    self.reminderTitleLabel.text = @"Remind on";
    self.reminderDateLabel.textColor = [UIColor blackColor];
    self.reminderDateLabel.text = [self.formatter stringFromDate:self.reminderDate];
}

- (void)pickerController:(FLReminderPickerController *)controller reminderRemoved:(BOOL)removed
{
    if (removed) {
        self.reminderDate = nil;
    }
    
    self.reminderTitleLabel.text = @"Add a reminder (Optional!)";
    self.reminderDateLabel.text = @" ";
    self.reminderDateLabel.textColor = [UIColor grayColor];
}

#pragma mark - Timing picker delegate methods.

- (void)pickerController:(FLTimingPickerController *)controller didSelectValue:(NSTimeInterval)selectedTime forPicker:(TimingPickerType)picker
{
    switch (picker) {
        case TaskTimePicker:
            self.taskTimeLabel.text = [NSString stringWithFormat:@"%f minutes", selectedTime];
            self.taskTime = selectedTime;
            break;
        case ShortBreakPicker:
            self.shortBreakLabel.text = [NSString stringWithFormat:@"%f minutes", selectedTime];
            self.shortBreakTime = selectedTime;
            break;
        case LongBreakPicker:
            self.longBreakLabel.text = [NSString stringWithFormat:@"%f minutes", selectedTime];
            self.longBreakTime = selectedTime;
            break;
    }
}

#pragma mark - ColorPicker delegate method.

- (void)colorPicker:(FLColorPicker *)controller didSelectColor:(UIColor *)flatColor forCycle:(NSString *)cycleName
{
    if ([cycleName isEqualToString:kTaskColorPicker]) {
        self.taskColor = flatColor;
    } else if ([cycleName isEqualToString:kShortBreakColorPicker]){
        self.shortBreakColor = flatColor;
    } else if ([cycleName isEqualToString:kLongBreakColorPicker]){
        self.longBreakColor = flatColor;
    }
}

@end
