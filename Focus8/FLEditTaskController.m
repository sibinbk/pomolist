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
#import "FLPickerController.h"
#import "FLColorPicker.h"
#import "FLDatePickerController.h"
#import "UIColor+FlatColors.h"
#import "Focus8-Swift.h"

#define kWorkTimePicker          @"workTimePicker"
#define kShortBreakPicker        @"shortBreakPicker"
#define kLongBreakPicker         @"longBreakPicker"
#define kLongBreakDelayPicker    @"longBreakDelayPicker"
#define kRepeatCountPicker       @"repeatCountPicker"
#define kTaskColorPicker         @"taskColorPicker"
#define kShortBreakColorPicker   @"shortBreakColorPicker"
#define kLongBreakColorPicker    @"longBreakColorPicker"

@interface FLEditTaskController () <FLPickerControllerDelegate, FLColorPickerDelegate, FLDatePickerControllerDelegate, UITextFieldDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSArray *workTimeArray;
@property (strong, nonatomic) NSArray *shortBreakArray;
@property (strong, nonatomic) NSArray *longBreakArray;
@property (strong, nonatomic) NSArray *repeatCountArray;
@property (strong, nonatomic) NSArray *longBreakDelayArray;

@property (weak, nonatomic) IBOutlet UITextField *taskNameField;
@property (weak, nonatomic) IBOutlet UILabel *reminderTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *reminderDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *workTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *shortBreakLabel;
@property (weak, nonatomic) IBOutlet UILabel *longBreakLabel;
@property (weak, nonatomic) IBOutlet UILabel *longBreakDelayLabel;
@property (weak, nonatomic) IBOutlet UILabel *repeatCountLabel;
@property (weak, nonatomic) IBOutlet DesignableView *taskColorView;
@property (weak, nonatomic) IBOutlet DesignableView *shortBreakColorView;
@property (weak, nonatomic) IBOutlet DesignableView *longBreakColorView;

@property (strong, nonatomic) FLDatePickerController *datePickerController;

@property (strong, nonatomic)NSDateFormatter *formatter;

@property (strong, nonatomic) UIColor *taskColor;
@property (strong, nonatomic) UIColor *shortBreakColor;
@property (strong, nonatomic) UIColor *longBreakColor;
@property (strong, nonatomic) NSDate *reminderDate;

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
    
    NSDictionary *contentDict = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PickerData" ofType:@"plist"]];
    self.workTimeArray = [contentDict objectForKey:@"WorkTime"];
    self.shortBreakArray = [contentDict objectForKey:@"ShortBreakTime"];
    self.longBreakArray = [contentDict objectForKey:@"LongBreakTime"];
    self.longBreakDelayArray = [contentDict objectForKey:@"LongBreakDelay"];
    self.repeatCountArray = [contentDict objectForKey:@"RepeatCount"];

    if ([self isTaskEditing]) {
        self.oldName = self.task.name;
        self.taskNameField.text = self.task.name;
        if (self.task.reminderDate != nil) {
            self.reminderTitleLabel.text = @"Remind on";
            self.reminderDateLabel.text = [self.formatter stringFromDate:self.task.reminderDate];
        }
        self.workTimeLabel.text = [NSString stringWithFormat:@"%@ minutes", self.task.workTime];
        self.shortBreakLabel.text = [NSString stringWithFormat:@"%@ minutes", self.task.shortBreakTime];
        self.longBreakLabel.text = [NSString stringWithFormat:@"%@ minutes", self.task.longBreakTime];
        self.longBreakDelayLabel.text = [NSString stringWithFormat:@"%@ tasks", self.task.longBreakDelay];
        self.repeatCountLabel.text = [NSString stringWithFormat:@"%@ times", self.task.repeatCount];
        self.taskColor = self.task.taskColor;
        self.shortBreakColor = self.task.shortBreakColor;
        self.longBreakColor = self.task.longBreakColor;
        
    } else {
        
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
        self.task.workTime = [NSNumber numberWithInteger: [self.workTimeLabel.text integerValue]];
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

#pragma mark - FLDatePickerController delegate methods.

- (void)pickerController:(FLDatePickerController *)controller reminderAdded:(NSDate *)reminderDate
{
    NSLog(@"Reminder date added : %@",reminderDate);
    self.reminderDate = reminderDate;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.reminderTitleLabel.text = @"Remind on";
        self.reminderDateLabel.text = [self.formatter stringFromDate:self.reminderDate];
        self.reminderDateLabel.textColor = [UIColor blackColor];
    });
}
- (void)pickerController:(FLDatePickerController *)controller reminderRemoved:(BOOL)removed
{
    NSLog(@"Reminder date removed");
    if (removed) {
        self.reminderDate = nil;
    }
    
    self.reminderTitleLabel.text = @"Set a reminder (Optional!)";
    self.reminderDateLabel.text = @" ";
    self.reminderDateLabel.textColor = [UIColor grayColor];
}

#pragma mark - tableview delegate method

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!(indexPath.section == 0 && indexPath.row == 0)) {
        [self.taskNameField resignFirstResponder];
    }
    
    NSString *pickerType;
    
    if (indexPath.section == 1 && indexPath.row == 0) {
        self.datePickerController = [[FLDatePickerController alloc] init];
        self.datePickerController.titleColor = self.taskColor;
        self.datePickerController.reminderDate = self.reminderDate;
        self.datePickerController.delegate = self;
        [self.datePickerController shoWDatePickerOnView:self.navigationController.view animated:YES];
    }
    
    if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0:
                pickerType = kWorkTimePicker;
                break;
            case 1:
                pickerType = kShortBreakPicker;
                break;
            case 2:
                pickerType = kLongBreakPicker;
                break;
            case 3:
                pickerType = kLongBreakDelayPicker;
                break;
            case 4:
                pickerType = kRepeatCountPicker;
                break;
            default:
                break;
        }
        
        [self performSegueWithIdentifier:@"pickerSegue" sender:pickerType];
    }
    
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
//    if ([segue.identifier isEqualToString:@"datePickerSegue"]) {
//        FLDatePickerController *datePickerController = segue.destinationViewController;
//        datePickerController.titleColor = [UIColor flatGreenSeaColor];
//        datePickerController.reminderDate = self.task.reminderDate;
//        datePickerController.delegate = self;
//    }
    
    if ([segue.identifier isEqualToString:@"pickerSegue"]) {
        FLPickerController *pickerController = segue.destinationViewController;
        pickerController.selectedPicker = sender;
        pickerController.delegate = self;
        
        if ([sender isEqualToString:kWorkTimePicker]) {
            pickerController.tableArray = self.workTimeArray;
            pickerController.selectedValue = self.workTimeLabel.text;
            pickerController.navigationItem.title = @"Work Time";
        } else if ([sender isEqualToString:kShortBreakPicker]) {
            pickerController.tableArray = self.shortBreakArray;
            pickerController.selectedValue = self.shortBreakLabel.text;
            pickerController.navigationItem.title = @"Short Break";
        } else if ([sender isEqualToString:kLongBreakPicker]) {
            pickerController.tableArray = self.longBreakArray;
            pickerController.selectedValue = self.longBreakLabel.text;
            pickerController.navigationItem.title = @"Long Break";
        } else if ([sender isEqualToString:kLongBreakDelayPicker]) {
            pickerController.tableArray = self.longBreakDelayArray;
            pickerController.selectedValue = self.longBreakDelayLabel.text;
            pickerController.navigationItem.title = @"Long Break Delay";
        } else if ([sender isEqualToString:kRepeatCountPicker]) {
            pickerController.tableArray = self.repeatCountArray;
            pickerController.selectedValue = self.repeatCountLabel.text;
            pickerController.navigationItem.title = @"Repeat Count";
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

- (void)pickerController:(FLPickerController *)controller didSelectValue:(NSString *)value forPicker:(NSString *)name
{
    if ([name isEqualToString:kWorkTimePicker]) {
        self.workTimeLabel.text = value;
    } else if ([name isEqualToString:kShortBreakPicker]){
        self.shortBreakLabel.text = value;
    } else if ([name isEqualToString:kLongBreakPicker]){
        self.longBreakLabel.text = value;
    } else if ([name isEqualToString:kLongBreakDelayPicker]){
        self.longBreakDelayLabel.text = value;
    } else if ([name isEqualToString:kRepeatCountPicker]){
        self.repeatCountLabel.text = value;
    }
        
    [self.navigationController popViewControllerAnimated:YES];
}

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
