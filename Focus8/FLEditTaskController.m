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
// #import "FLReminderPickerController.h"
#import "FLTimingPickerController.h"
#import "FLBreakDelayPickerController.h"
#import "FLSessionCountPickerController.h"
#import "UIColor+FlatColors.h"
#import "ColorUtils.h"
#import "Focus8-Swift.h"

#define kTaskTimePicker          @"taskTimePicker"
#define kShortBreakPicker        @"shortBreakPicker"
#define kLongBreakPicker         @"longBreakPicker"
#define kLongBreakDelayPicker    @"longBreakDelayPicker"
#define kRepeatCountPicker       @"repeatCountPicker"
#define kTaskColorPicker         @"taskColorPicker"
#define kShortBreakColorPicker   @"shortBreakColorPicker"
#define kLongBreakColorPicker    @"longBreakColorPicker"

@interface FLEditTaskController () <UITextFieldDelegate, FLTimingPickerDelegate, FLBreakDelayPickerDelagate, FLSessionCountPickerDelegate, FLColorPickerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSArray *taskTimeArray;
@property (strong, nonatomic) NSArray *shortBreakArray;
@property (strong, nonatomic) NSArray *longBreakArray;
@property (strong, nonatomic) NSArray *repeatCountArray;
@property (strong, nonatomic) NSArray *longBreakDelayArray;

@property (weak, nonatomic) IBOutlet UITextField *taskNameField;
/*
@property (weak, nonatomic) IBOutlet UILabel *reminderTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *reminderDateLabel;
 */
@property (weak, nonatomic) IBOutlet UILabel *taskTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *shortBreakLabel;
@property (weak, nonatomic) IBOutlet UILabel *longBreakLabel;
@property (weak, nonatomic) IBOutlet UILabel *longBreakDelayLabel;
@property (weak, nonatomic) IBOutlet UILabel *taskGoalLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTaskTimeLabel;
@property (weak, nonatomic) IBOutlet DesignableView *taskColorView;
@property (weak, nonatomic) IBOutlet DesignableView *shortBreakColorView;
@property (weak, nonatomic) IBOutlet DesignableView *longBreakColorView;

@property (assign, nonatomic) TimingPickerType timingPickerType;

@property (strong, nonatomic) NSString *taskName;
@property (strong, nonatomic) NSString *uniqueID;
@property (nonatomic) NSTimeInterval taskTime;
@property (nonatomic) NSTimeInterval shortBreakTime;
@property (nonatomic) NSTimeInterval longBreakTime;
@property (nonatomic) NSTimeInterval totalCountDownTime;
@property (nonatomic) NSInteger repeatCount;
@property (nonatomic) NSInteger longBreakDelay;
@property (strong, nonatomic) NSString *taskColorString;
@property (strong, nonatomic) NSString *shortBreakColorString;
@property (strong, nonatomic) NSString *longBreakColorString;
/* 
@property (strong, nonatomic) NSDate *reminderDate;
@property (strong, nonatomic) NSDateFormatter *formatter;
*/

@property (strong, nonatomic) NSArray *colorStringArray;

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

    /* Date formatter code.
     
    //Setup date formatter
    self.formatter = [[NSDateFormatter alloc] init];
    NSString *format = [NSDateFormatter dateFormatFromTemplate:@"MMM d, yyyy hh:mm a" options:0 locale:[NSLocale currentLocale]];
    [self.formatter setDateFormat:format];
    */
    
    self.colorStringArray = @[@"C0392B",
                              @"E74C3C",
                              @"D35400",
                              @"E67E22",
                              @"16A085",
                              @"1ABC9C",
                              @"27AE60",
                              @"2980B9",
                              @"3498DB",
                              @"8E44AD",
                              @"673AB7"];
    
    /* Above Colorstrings are,
                Pomegranate
                Alizarin
                Pumpkin
                Carrot
                Green Sea
                Turquoise
                Nephritis
                Belize Hole
                Deep Purple
     */
    
    if ([self isTaskEditing]) {
        self.oldName = self.task.name;
        self.taskNameField.text = self.task.name;
        /*
        if (self.task.reminderDate != nil) {
            self.reminderTitleLabel.text = @"Remind on";
            self.reminderDateLabel.text = [self.formatter stringFromDate:self.task.reminderDate];
        }
        */
        self.taskTimeLabel.text = [self stringifyTime:[self.task.taskTime intValue]];
        self.shortBreakLabel.text = [self stringifyTime:[self.task.shortBreakTime intValue]];
        self.longBreakLabel.text = [self stringifyTime:[self.task.longBreakTime intValue]];
        
        if ([self.task.longBreakDelay intValue] == 1) {
            self.longBreakDelayLabel.text = [NSString stringWithFormat:@"%d pomodoro", [self.task.longBreakDelay intValue]];
        } else {
            self.longBreakDelayLabel.text = [NSString stringWithFormat:@"%d pomodoros", [self.task.longBreakDelay intValue]];
        }
        
        if ([self.task.repeatCount intValue] == 1) {
            self.taskGoalLabel.text = [NSString stringWithFormat:@"%d pomodoro", [self.task.repeatCount intValue]];
        } else {
            self.taskGoalLabel.text = [NSString stringWithFormat:@"%d pomodoros", [self.task.repeatCount intValue]];
        }
        
        self.totalTaskTimeLabel.text = [self stringifyTotalTaskTime:([self.task.taskTime intValue] * [self.task.repeatCount intValue]) usingLongFormat:YES];

/*
        self.reminderDate = self.task.reminderDate; // Empty reminder date. 
 */
        self.taskTime = [self.task.taskTime doubleValue];
        self.shortBreakTime = [self.task.shortBreakTime doubleValue];
        self.longBreakTime = [self.task.longBreakTime doubleValue];
        self.longBreakDelay = [self.task.longBreakDelay integerValue];
        self.repeatCount = [self.task.repeatCount integerValue];
        self.taskColorString = self.task.taskColorString;
        self.shortBreakColorString = self.task.shortBreakColorString;
        self.longBreakColorString = self.task.longBreakColorString;
        
    } else {
        self.uniqueID = [NSString stringWithFormat:@"%@",[NSDate date]];
        self.taskTime = 1500; // Task session 30 mins.
        self.shortBreakTime = 300; // Short break 5 mins.
        self.longBreakTime = 900; // Long break 15 mins.
        self.longBreakDelay = 3;
        self.repeatCount = 5;

        // Assign random color to task cycle while creating new task.
        
        NSUInteger randomIndex = arc4random_uniform(11);
        
        self.taskColorString = self.colorStringArray[randomIndex];
        self.shortBreakColorString = @"34495E"; // Wet Asphalt
        self.longBreakColorString = @"2C3E50";  // Midnight Blue
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    self.taskColorView.backgroundColor = [UIColor colorWithString:self.taskColorString];
    self.shortBreakColorView.backgroundColor = [UIColor colorWithString:self.shortBreakColorString];
    self.longBreakColorView.backgroundColor = [UIColor colorWithString:self.longBreakColorString];
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
            
            // Set unique ID when task is created for the first time.
            self.task.uniqueID = self.uniqueID;
        }
        
        self.task.name = self.taskNameField.text;
        self.task.taskTime = [NSNumber numberWithDouble:self.taskTime];
        self.task.shortBreakTime = [NSNumber numberWithDouble:self.shortBreakTime];
        self.task.longBreakTime = [NSNumber numberWithDouble:self.longBreakTime];
        self.task.longBreakDelay = [NSNumber numberWithInteger:self.longBreakDelay];
        self.task.repeatCount = [NSNumber numberWithInteger:self.repeatCount];
        
        // Task objectstores cycle colors as Hex string.
        
        self.task.taskColorString = self.taskColorString;
        self.task.shortBreakColorString = self.shortBreakColorString;
        self.task.longBreakColorString = self.longBreakColorString;
        
        // Adds nil to reminder date.
        self.task.reminderDate = nil;
        
/* Reminder date handling code here. */
 
//        NSLog(@"Old reinder date : %@", self.task.reminderDate);
//        NSLog(@"New reminder date : %@", self.reminderDate);
//        if (![self.task.reminderDate isEqualToDate:self.reminderDate]) {
//            if (!self.task.reminderDate) {
//                if (self.reminderDate) {
//                    self.task.reminderDate = self.reminderDate;
//                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                        NSLog(@"schedule reminder notification");
//                        [self scheduleReminderNotificationForTask:self.task];
//                    });
//                } else {
//                    NSLog(@"Both dates are nill");
//                    /* This line executes when bothe Reimder dates are nill but not captured while comparing both dates. */
//                }
//            } else {
//                if (!self.reminderDate) {
//                    self.task.reminderDate = nil;
//                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                        NSLog(@"cancel old reminder notification");
//                        [self cancelReminderNotificationForTask:self.task];
//                    });
//                } else {
//                    self.task.reminderDate = self.reminderDate;
//                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                        NSLog(@"cancel old reminder notification");
//                        [self cancelReminderNotificationForTask:self.task];
//                    });
//                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                        NSLog(@"schedule reminder notification");
//                        [self scheduleReminderNotificationForTask:self.task];
//                    });
//                }
//            }
//        } else {
//            NSLog(@"No change in reminder date");
//        }
        
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

#pragma mark - schedule local notifications for Reminder date

/* Reminder notification code.
 
- (void)scheduleReminderNotificationForTask:(Task *)task
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.fireDate = task.reminderDate;
    notification.alertBody = [NSString stringWithFormat:@"%@ is due now", task.name];
    notification.userInfo = @{@"uniqueID" : task.uniqueID};
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)cancelReminderNotificationForTask:(Task *)task
{
    for (UILocalNotification *notification in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        NSDictionary *userInfoCurrent = notification.userInfo;
        NSString *uniqueID = [userInfoCurrent valueForKey:@"uniqueID"];
        if ([uniqueID isEqualToString:task.uniqueID])
        {
            NSLog(@"UID : %@", uniqueID);
            //Cancelling local notification
            [[UIApplication sharedApplication] cancelLocalNotification:notification];
        }
    }
}
*/

#pragma mark - tableview delegate method

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!(indexPath.section == 0 && indexPath.row == 0)) {
        [self.taskNameField resignFirstResponder];
    }
    
    /* Reminder picker segue method.
     
    if (indexPath.section == 1 && indexPath.row == 0) {
        [self performSegueWithIdentifier:@"reminderPickerSegue" sender:nil];
    }
     */
    
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            self.timingPickerType = TaskTimePicker;
            [self performSegueWithIdentifier:@"timingPickerSegue" sender:nil];
        } else if (indexPath.row == 1) {
            self.timingPickerType = ShortBreakPicker;
            [self performSegueWithIdentifier:@"timingPickerSegue" sender:nil];
        } else if (indexPath.row == 2) {
            self.timingPickerType = LongBreakPicker;
            [self performSegueWithIdentifier:@"timingPickerSegue" sender:nil];
        } else if (indexPath.row == 3) {
            [self performSegueWithIdentifier:@"breakDelayPickerSegue" sender:nil];
        }
    }
    
    if (indexPath.section == 2) {
        if (indexPath.row == 0){
            [self performSegueWithIdentifier:@"sessionCountSegue" sender:nil];
        }
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
    /* prepare segue method for Reminder picker.
     
    if ([segue.identifier isEqualToString:@"reminderPickerSegue"]) {
        FLReminderPickerController *reminderPicker = segue.destinationViewController;
        reminderPicker.reminderDate = self.reminderDate;
        reminderPicker.delegate = self;
    }
     */
    
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
    
    if ([segue.identifier isEqualToString:@"breakDelayPickerSegue"]) {
        FLBreakDelayPickerController *breakDelayPicker = segue.destinationViewController;
        breakDelayPicker.selectedValue = self.longBreakDelay;
        breakDelayPicker.delegate = self;
    }
    
    if ([segue.identifier isEqualToString:@"sessionCountSegue"]) {
        FLSessionCountPickerController *sessionCountPicker = segue.destinationViewController;
        sessionCountPicker.selectedTaskSessionTime = self.taskTime;
        sessionCountPicker.selectedTaskSessionCount = self.repeatCount;
        sessionCountPicker.delegate = self;
    }
    
    if ([segue.identifier isEqualToString:@"colorPickerSegue"]) {
        FLColorPicker *colorPicker = segue.destinationViewController;
        colorPicker.selectedPicker = sender;
        colorPicker.delegate = self;
        
        if ([sender isEqualToString:kTaskColorPicker]) {
            colorPicker.selectedColorString = self.taskColorString;
            colorPicker.navigationItem.title = @"Pomodoro";
        } else if ([sender isEqualToString:kShortBreakColorPicker]) {
            colorPicker.selectedColorString = self.shortBreakColorString;
            colorPicker.navigationItem.title = @"Short Break";
        } else if ([sender isEqualToString:kLongBreakColorPicker]) {
            colorPicker.selectedColorString = self.longBreakColorString;
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

/* Date picker delegate methods.
 
- (void)pickerController:(FLReminderPickerController *)controller reminderSetOn:(NSDate *)reminderDate
{
    self.reminderDate = [self truncateSecondsForDate:reminderDate];
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
*/

#pragma mark - Timing picker delegate methods.

- (void)pickerController:(FLTimingPickerController *)controller didSelectValue:(NSTimeInterval)selectedTime forPicker:(TimingPickerType)picker
{
    switch (picker) {
        case TaskTimePicker:
            self.taskTimeLabel.text = [self stringifyTime:selectedTime];
            self.totalTaskTimeLabel.text = [self stringifyTotalTaskTime:(selectedTime * self.repeatCount) usingLongFormat:YES];
            self.taskTime = selectedTime;
            break;
        case ShortBreakPicker:
            self.shortBreakLabel.text = [self stringifyTime:selectedTime];
            self.shortBreakTime = selectedTime;
            break;
        case LongBreakPicker:
            self.longBreakLabel.text = [self stringifyTime:selectedTime];
            self.longBreakTime = selectedTime;
            break;
    }
}

#pragma mark - Long Break Delay picker delegate method.

- (void)pickerController:(FLBreakDelayPickerController *)controller didSelectDelay:(NSInteger)delay
{
    self.longBreakDelay = delay;
    
    if (delay == 1) {
        self.longBreakDelayLabel.text = [NSString stringWithFormat:@"%d pomodoro", (int)delay];
    } else {
        self.longBreakDelayLabel.text = [NSString stringWithFormat:@"%d pomodoros", (int)delay];
    }
}

# pragma mark - Target session count picker delagate.

- (void)pickerController:(FLSessionCountPickerController *)controller didSelectTargetPomodoroCount:(NSInteger)count
{
    self.repeatCount = count;
    
    if (count == 1) {
        self.taskGoalLabel.text = [NSString stringWithFormat:@"%d pomodoro", (int)count];
    } else {
        self.taskGoalLabel.text = [NSString stringWithFormat:@"%d pomodoros", (int)count];
    }
    
    self.totalTaskTimeLabel.text = [self stringifyTotalTaskTime:(self.taskTime * count) usingLongFormat:YES];
}

#pragma mark - ColorPicker delegate method.

- (void)colorPicker:(FLColorPicker *)controller didSelectColor:(NSString *)colorString forPicker:(NSString *)picker
{
    if ([picker isEqualToString:kTaskColorPicker]) {
        self.taskColorString = colorString;
    } else if ([picker isEqualToString:kShortBreakColorPicker]){
        self.shortBreakColorString = colorString;
    } else if ([picker isEqualToString:kLongBreakColorPicker]){
        self.longBreakColorString = colorString;
    }
}

#pragma mark - StringifyTime methods.

- (NSString *)stringifyTime:(int)time
{
    if (time < 60) {
        return [NSString stringWithFormat:@"%d seconds", (int)time];
    } else if (time == 60){
        return [NSString stringWithFormat:@"%d minute", (int)time / 60];
    } else {
        return [NSString stringWithFormat:@"%d minutes", (int)time / 60];
    }
}

- (NSString *)stringifyTotalTaskTime:(int)seconds usingLongFormat:(BOOL)longFormat
{
    int remainingSeconds = seconds;
    
    int hours = remainingSeconds / 3600;
    
    remainingSeconds = remainingSeconds - hours * 3600;
    
    int minutes = remainingSeconds / 60;
    
    remainingSeconds = remainingSeconds - minutes * 60;
    
    if (longFormat) {
        if (hours > 0) {
            if (minutes > 0) {
                return [NSString stringWithFormat:@"%i hr %i min", hours, minutes];
            } else {
                return [NSString stringWithFormat:@"%i hr", hours];
            }
        } else {
            return [NSString stringWithFormat:@"%i min", minutes];
        }
    } else {
        if (hours > 0) {
            return [NSString stringWithFormat:@"%02i:%02i", hours, minutes];
        } else {
            return [NSString stringWithFormat:@"%02i", minutes];
        }
    }
}

#pragma mark - Reminder date's second component truncation method.

/*
- (NSDate *)truncateSecondsForDate:(NSDate *)fromDate;
{
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSCalendarUnit unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
    NSDateComponents *fromDateComponents = [calendar components:unitFlags fromDate:fromDate ];
    return [calendar dateFromComponents:fromDateComponents];
}
*/
@end
