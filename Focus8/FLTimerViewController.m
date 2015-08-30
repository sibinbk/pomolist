//
//  FLTimerViewController.m
//  Focus8
//
//  Created by Sibin Baby on 7/11/2014.
//  Copyright (c) 2014 FocusApps. All rights reserved.
//

#import "FLTimerViewController.h"
#import "AppDelegate.h"
#import "FLEditTaskController.h"
#import "ZGCountDownTimer.h"
#import "Task.h"
#import "Event.h"
#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"
#import "UIColor+FlatColors.h"
#import "FLTaskCell.h"

static NSString * const kFLScreenLockUserDefaultsKey = @"kFLScreenLockUserDefaultsKey";

#define kFLTaskName                @"taskName"
#define kFLTaskTime                @"taskTime"
#define kFLShortBreakTime          @"shortBreakTime"
#define kFLLongBreakTime           @"longBreakTime"
#define kFLRepeatCount             @"repeatCount"
#define kFLLongBreakDelay          @"longBreakDelay"
#define kFLTaskColor               @"taskColor"
#define kFLShortBreakColor         @"shortBreakColor"
#define kFLLongBreakColor          @"longBreakColor"

#define kFLUserDefaultKey          @"FocusListUserDefaults"
#define kFLRepeatTimer             @"FLRepeatTimer"
#define kFLTimerNotification       @"FLTimerNotification"

@interface FLTimerViewController () <ZGCountDownTimerDelegate, FLTaskControllerDelegate, UITableViewDataSource, UITableViewDelegate, MGSwipeTableCellDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic) NSTimeInterval taskTime;
@property (nonatomic) NSTimeInterval shortBreakTime;
@property (nonatomic) NSTimeInterval longBreakTime;
@property (nonatomic) NSTimeInterval totalCountDownTime;
@property (nonatomic) NSInteger repeatCount;
@property (nonatomic) NSInteger longBreakDelay;
@property (strong, nonatomic) NSString *taskName;
@property (strong, nonatomic) UIColor *taskColor;
@property (strong, nonatomic) UIColor *shortBreakColor;
@property (strong, nonatomic) UIColor *longBreakColor;
@property (strong, nonatomic) NSString *alarmSound;

@property (strong, nonatomic) NSDateFormatter *formatter;

@property (assign, nonatomic) BOOL isFullView;
@property (assign, nonatomic) BOOL isTaskEditing;

@property (weak, nonatomic) IBOutlet UILabel *taskTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (weak, nonatomic) IBOutlet UILabel *cycleLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTaskTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *listButton;
@property (weak, nonatomic) IBOutlet UIButton *eventListButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *timerViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *timerLabelSpacing;
@property (weak, nonatomic) IBOutlet UITableView *taskTableView;

@property(strong, nonatomic) ZGCountDownTimer *repeatTimer;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSFetchedResultsController *fetchedResultsController;

@end

@implementation FLTimerViewController

@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Read Screen Lock Prevent status from UserDefaults.
    [self readScreenLockOnFromUserDefaults];
    
    //Setup date formatter
    self.formatter = [[NSDateFormatter alloc] init];
    NSString *format = [NSDateFormatter dateFormatFromTemplate:@"MMM dd 'at' h:mm a" options:0 locale:[NSLocale currentLocale]];
    [self.formatter setDateFormat:format];
    
    if ([self backupExist]) {
        [self restoreTaskInfo];
        self.taskTitleLabel.text = self.taskName;
    } else {
        self.taskTitleLabel.text = @"";
        self.taskTime = 20;
        self.shortBreakTime = 15;
        self.longBreakTime = 20;
        self.repeatCount = 3;
        self.longBreakDelay = 2;
        self.taskColor = [UIColor flatAmethystColor];
        self.shortBreakColor = [UIColor flatWetAsphaltColor];
        self.longBreakColor = [UIColor flatPomegranateColor];
    }

    self.isFullView = YES;
    self.timerViewHeight.constant = CGRectGetHeight(self.view.frame);
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showListView)];
    [swipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
    [self.mainView addGestureRecognizer:swipeUp];
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeListView)];
    [swipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.mainView addGestureRecognizer:swipeDown];
    
    NSError *error = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error in loading data", @"Error in loading data")
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Error was: %@, quitting.", @"Error was: %@, quitting."), [error localizedDescription]]
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    self.repeatTimer = [ZGCountDownTimer countDownTimerWithIdentifier:kFLRepeatTimer];
    self.repeatTimer.delegate = self;
    
    [self repeatTimerSetup];
}

- (void)repeatTimerSetup
{
    self.totalCountDownTime = [self calculateTotalCountDownTime];
    NSLog(@"Total count down time : %f", self.totalCountDownTime);
    
    __weak FLTimerViewController *weakSelf = self;
    [self.repeatTimer setupCountDownForTheFirstTime:^(ZGCountDownTimer *timer) {
        timer.taskTime = weakSelf.taskTime;
        timer.shortBreakTime = weakSelf.shortBreakTime;
        timer.longBreakTime = weakSelf.longBreakTime;
        timer.repeatCount = weakSelf.repeatCount;
        timer.longBreakDelay = weakSelf.longBreakDelay;
        timer.totalCountDownTime = weakSelf.totalCountDownTime;
    } restoreFromBackUp:^(ZGCountDownTimer *timer) {
        NSLog(@"Restores from ZGCountDown backup");
    }];
    
    if (!self.repeatTimer.isRunning) {
        if (!self.repeatTimer.started) {
            [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
            self.resetButton.hidden = YES;
        } else {
            [self.startButton setTitle:@"Resume" forState:UIControlStateNormal];
            self.resetButton.hidden = NO;
        }
        // Chcek if it fullview before un-hiding the skip button.
        if (![self isFullView]) {
            self.skipButton.hidden = YES;
        } else {
            self.skipButton.hidden = NO;
        }
    } else {
        [self.startButton setTitle:@"Pause" forState:UIControlStateNormal];
        self.resetButton.hidden = NO;
        self.skipButton.hidden = YES;
    }
}

- (NSTimeInterval)calculateTotalCountDownTime
{
    int longBreakCount = 0;
    
    if (self.longBreakDelay > 0) {
        longBreakCount = (int)(self.repeatCount / self.longBreakDelay);
    }
    
    NSTimeInterval totalTime = self.taskTime * self.repeatCount + self.shortBreakTime * (self.repeatCount - longBreakCount) + self.longBreakTime * longBreakCount;
    
    return totalTime;
}

# pragma mark - View handling methods.

- (void)closeListView
{
    [self.view setNeedsUpdateConstraints];
    self.timerViewHeight.constant = CGRectGetHeight(self.view.frame);
    self.timerLabelSpacing.constant = 180.0f;
    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.8
                        options:0
                     animations:^{
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         self.startButton.hidden = NO;
                         self.taskTitleLabel.hidden = NO;
                         self.cycleLabel.hidden = NO;
                         self.totalTaskTimeLabel.hidden = NO;
                         self.editButton.hidden = NO;
                         self.eventListButton.hidden = NO;
                         if (!self.repeatTimer.started) {
                             self.resetButton.hidden = YES;
                         } else {
                             self.resetButton.hidden = NO;
                         }
                         
                         // Chcek if the timer is paused before un-hiding the skip button.
                         if (!self.repeatTimer.isRunning) {
                             self.skipButton.hidden = NO;
                         } else
                         {
                             self.skipButton.hidden = YES;
                         }
                     }];
    self.isFullView = YES;
    [self.listButton.imageView setImage:[UIImage imageNamed:@"menu.png"]];
}
- (void)showListView
{
    [self.view setNeedsUpdateConstraints];
    self.timerViewHeight.constant = 80;
    self.timerLabelSpacing.constant = 20.0f;
    self.startButton.hidden = YES;
    self.resetButton.hidden = YES;
    self.skipButton.hidden = YES;
    self.editButton.hidden = YES;
    self.eventListButton.hidden = YES;
    self.taskTitleLabel.hidden = YES;
    self.cycleLabel.hidden = YES;
    self.totalTaskTimeLabel.hidden = YES;
//    [UIView animateWithDuration:0.5 animations:^{
//        [self.view layoutIfNeeded];
//    } completion:^(BOOL finished) {
//    }];
//    self.isFullView = NO;
//    [self.listButton.imageView setImage:[UIImage imageNamed:@"delete.png"]];
    
    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.7
                        options:0
                     animations:^{
                         [self.view layoutIfNeeded];
                     } completion:NULL];
    self.isFullView = NO;
    [self.listButton.imageView setImage:[UIImage imageNamed:@"delete.png"]];
}

- (IBAction)showTaskList:(id)sender
{
    if (![self isFullView]) {
        [self closeListView];
    } else {
        [self showListView];
    }
}

#pragma mark - Timer methods.

- (IBAction)startTimer:(id)sender
{
    if (self.taskTime == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert!!"
                                                            message:@"No task available, Please select one from the list"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        
        return;
    }
    
    if (![self.repeatTimer isRunning]) {
        [self.repeatTimer startCountDown];
        [self.startButton setTitle:@"Pause" forState:UIControlStateNormal];
        self.resetButton.hidden = NO;
        self.skipButton.hidden = YES;

        // GCD to avoid blocking UI when the loacal notification setup loop runs.
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"Setup local notification");
            [self scheduleTimerNotifications];
        });
    } else {
        [self.repeatTimer pauseCountDown];
        if (!self.repeatTimer.started) {
            [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
            self.resetButton.hidden = YES;
        } else {
            [self.startButton setTitle:@"Resume" forState:UIControlStateNormal];
            self.resetButton.hidden = NO;
        }
        
        self.skipButton.hidden = NO;

        // GCD to avoid blocking UI while cancelling local notifications.
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"Cancel Timer notifications while Pause");
            [self cancelTimerNotifications];
        });
    }
}

- (IBAction)resetTimer:(id)sender
{
    if (self.taskTime == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert!!"
                                                            message:@"No task available, Please select one from the list"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        
        return;
    }

    //GCD to avoid blocking UI while cancelling local notifications.
    if (self.repeatTimer.isRunning) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"Cancel Timer notification during reset");
            [self cancelTimerNotifications];
        });
    }

    [self.repeatTimer stopCountDown];
    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    self.resetButton.hidden = YES;
    
    // Chcek if it fullview before un-hiding the skip button.
    if (![self isFullView]) {
        self.skipButton.hidden = YES;
    } else
    {
        self.skipButton.hidden = NO;
    }
}

- (IBAction)skipTimer:(id)sender
{
    if (self.taskTime == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert!!"
                                                            message:@"No task available, Please select one from the list"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        
        return;
    }

    [self.repeatTimer skipCountDown];
    
    if (!self.repeatTimer.started) {
        self.resetButton.hidden = YES;
    } else {
        self.resetButton.hidden = NO;
    }
}

#pragma mark - schedule local notifications.

- (void)scheduleTimerNotifications
{
    NSTimeInterval tempCycleFinishTime = self.repeatTimer.cycleFinishTime;
    NSTimeInterval timePassed = self.repeatTimer.timePassed;
    CountDownCycleType cycleType = self.repeatTimer.cycleType;
    NSInteger taskCount = self.repeatTimer.taskCount;
    NSInteger cycleCount = self.repeatTimer.timerCycleCount;
    
    int notificationCount = (int)(self.repeatCount * 2 - cycleCount);
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.soundName = @"RingRing.wav";
    notification.userInfo = @{@"timerNotificationID" : kFLTimerNotification};
    
    for (int i = 0; i < notificationCount; i++) {
        NSLog(@"Notication No : %i", i);
        // Specify custom data for the notification
//        NSDictionary *infoDict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%i", i] forKey:[NSString stringWithFormat:@"%i", i]];
        
        switch (cycleType) {
            case TaskCycle:
                notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:(tempCycleFinishTime - timePassed)];
                notification.alertBody = [NSString stringWithFormat:@"Task Cycle # %d completed. Have a break.", (int)taskCount] ;
                if (![self checkIfLongBreakCycle:taskCount]) {
                    cycleType = ShortBreakCycle;
                    tempCycleFinishTime += self.shortBreakTime;
                } else {
                    cycleType = LongBreakCycle;
                    tempCycleFinishTime += self.longBreakTime;
                }
                break;
                
            case ShortBreakCycle:
                notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:(tempCycleFinishTime - timePassed)];
                notification.alertBody = @"Short Break completed";
                cycleType = TaskCycle;
                tempCycleFinishTime += self.taskTime;
                taskCount++;
                break;
                
            case LongBreakCycle:
                notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:(tempCycleFinishTime - timePassed)];
                notification.alertBody = @"Long Break completed";
                cycleType = TaskCycle;
                tempCycleFinishTime += self.taskTime;
                taskCount++;
                break;
        }
        
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:(self.totalCountDownTime - timePassed)];
    notification.alertBody = @"Well done. Task finished.";
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (BOOL)checkIfLongBreakCycle:(NSInteger)taskCount
{
    if (self.longBreakDelay > 0) {
        if (taskCount % self.longBreakDelay == 0) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

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

#pragma mark - cancel local notifications.

- (void)cancelTimerNotifications
{
    for (UILocalNotification *notification in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        NSDictionary *userInfoCurrent = notification.userInfo;
        //        NSString *uid = [NSString stringWithFormat:@"%@", [userInfoCurrent valueForKey:@"name"]];
        NSString *uid = [userInfoCurrent valueForKey:@"timerNotificationID"];
        if ([uid isEqualToString:kFLTimerNotification])
        {
            NSLog(@"UID : %@", uid);
            //Cancelling local notification
            [[UIApplication sharedApplication] cancelLocalNotification:notification];
        }
    }
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

- (void)cancelAllNotificationsForTask:(Task *)task
{
    for (UILocalNotification *notification in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        NSDictionary *userInfo = notification.userInfo;
        NSString *uniqueID = [userInfo valueForKey:@"uniqueID"];
        NSString *timerNotificationID = [userInfo valueForKey:@"timerNotificationID"];
        if ([uniqueID isEqualToString:task.uniqueID] || [timerNotificationID isEqualToString:kFLTimerNotification]) {
            NSLog(@"Local notifcation Cancelled");
            [[UIApplication sharedApplication] cancelLocalNotification:notification];
        }
    }
}

#pragma mark - Delegate methods.

- (void)secondUpdated:(ZGCountDownTimer *)sender countDownTimePassed:(NSTimeInterval)timePassed ofTotalTime:(NSTimeInterval)totalTime
{
    // Conversion to Time string without hour component.
    self.timerLabel.text = [self dateStringForTimeIntervalWithoutHour:(totalTime - timePassed) withDateFormatter:nil];
}

- (void)taskTimeUpdated:(ZGCountDownTimer *)sender totalTime:(NSTimeInterval)time
{
    self.totalTaskTimeLabel.text = [self getDateStringForTimeInterval:time];
}

- (void)taskFinished:(ZGCountDownTimer *)sender totalTaskTime:(NSTimeInterval)time
{
//    NSArray *taskArray = [self currentSelectedTask];
    [self saveEventOfTask:[self currentSelectedTask] withTotalTime:time];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.resetButton.hidden = YES;
        self.skipButton.hidden = NO;
        // Set start button title to 'START' after finishing timer.
        [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    });
    
//    self.resetButton.hidden = YES;
//    self.skipButton.hidden = NO;
//    // Set start button title to 'START' after finishing timer.
//    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Task Completed"
                                                        message:[NSString stringWithFormat:@"Total Task Time : %f", time]
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
    [alertView show];

}
- (void)countDownCycleChanged:(ZGCountDownTimer *)sender cycle:(CountDownCycleType)newCycle withTaskCount:(NSInteger)count
{
    UIColor *viewColor;
    NSString *cycleTitle;
    
    switch (newCycle) {
        case TaskCycle:
            cycleTitle = [NSString stringWithFormat:@"Pomodoro # %ld", (long) count];
//            viewColor = [UIColor colorWithRed:0.976 green:0.369 blue:0.31 alpha:1];
            viewColor = self.taskColor;
            break;
        case ShortBreakCycle:
            cycleTitle = @"Short Break";
//            viewColor = [UIColor colorWithRed:0.22 green:0.565 blue:0.847 alpha:1];
            viewColor = self.shortBreakColor;
            break;
        case LongBreakCycle:
            cycleTitle = @"Long Break";
//            viewColor = [UIColor colorWithRed:0.827 green:0.4 blue:1 alpha:1]; /*#d366ff*/
            viewColor = self.longBreakColor;
            break;
        default:
            break;
    }
    
    self.cycleLabel.text = cycleTitle;
    [UIView animateWithDuration:0.5 animations:^{
        self.mainView.backgroundColor = viewColor;
    }];
}

- (void)countDownCompleted:(ZGCountDownTimer *)sender {
    self.resetButton.hidden = YES;
    self.skipButton.hidden = NO;
//     Set start button title to 'START' after finishing timer.
    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Task Completed"
                                                        message:@"Count down completed"
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
    [alertView show];
    
}

- (void)taskCompleted:(ZGCountDownTimer *)sender {
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Task Finished" message:@"Task Cycle Completed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alertView show];
}

- (void)shortBreakCompleted:(ZGCountDownTimer *)sender {
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Short Break Finished" message:@"Short Break Cycle Completed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alertView show];
}

- (void)longBreakCompleted:(ZGCountDownTimer *)sender{
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Long Break Finished" message:@"Long Break Cycle Completed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alertView show];
}

#pragma mark - Save Task event method.

- (void)saveEventOfTask:(Task *)task withTotalTime:(NSTimeInterval)totalTime
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSEntityDescription *eventEntity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:context];
    
    //Initialize Event.
    Event *event = [[Event alloc] initWithEntity:eventEntity insertIntoManagedObjectContext:context];
    
    //Populate Event details.
    event.finishDate = [NSDate date];
    event.totalTaskTime = [NSNumber numberWithDouble:totalTime];
    
    [task addEventsObject:event];
    
    [self saveContext];
}

#pragma mark - backup/restore methods

- (void)readScreenLockOnFromUserDefaults
{
    NSNumber *setting = [[NSUserDefaults standardUserDefaults] objectForKey:kFLScreenLockUserDefaultsKey];
    
    if (!setting) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    } else {
        [[UIApplication sharedApplication] setIdleTimerDisabled:[setting boolValue]];
    }
}

- (BOOL)backupExist
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *taskInfo = [defaults objectForKey:kFLUserDefaultKey];
    return taskInfo != nil;
}

- (void)backUpTaskInfo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self taskInfoForBackup] forKey:kFLUserDefaultKey];
    [defaults synchronize];
}

- (void)restoreTaskInfo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self restoreFromTaskInfoBackup:[defaults objectForKey:kFLUserDefaultKey]];
}

- (void)removeTaskInfoBackup
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kFLUserDefaultKey];
    [defaults synchronize];
}

- (NSDictionary *)taskInfoForBackup
{
    return @{
             kFLTaskName: self.taskName,
             kFLTaskTime: [NSNumber numberWithDouble:self.taskTime],
             kFLShortBreakTime: [NSNumber numberWithDouble:self.shortBreakTime],
             kFLLongBreakTime: [NSNumber numberWithDouble:self.longBreakTime],
             kFLRepeatCount: [NSNumber numberWithInteger:self.repeatCount],
             kFLLongBreakDelay: [NSNumber numberWithInteger:self.longBreakDelay],
             kFLTaskColor: [NSKeyedArchiver archivedDataWithRootObject:self.taskColor],
             kFLShortBreakColor: [NSKeyedArchiver archivedDataWithRootObject:self.shortBreakColor],
             kFLLongBreakColor: [NSKeyedArchiver archivedDataWithRootObject:self.longBreakColor]
             };
}

- (void)restoreFromTaskInfoBackup:(NSDictionary *)taskInfo
{
    self.taskName = [taskInfo valueForKey:kFLTaskName];
    self.taskTime = [[taskInfo valueForKey:kFLTaskTime] doubleValue];
    self.shortBreakTime = [[taskInfo valueForKey:kFLShortBreakTime] doubleValue];
    self.longBreakTime = [[taskInfo valueForKey:kFLLongBreakTime] doubleValue];
    self.repeatCount = [[taskInfo valueForKey:kFLRepeatCount] integerValue];
    self.longBreakDelay = [[taskInfo valueForKey:kFLLongBreakDelay] integerValue];
    self.taskColor = [NSKeyedUnarchiver unarchiveObjectWithData:[taskInfo valueForKey:kFLTaskColor]];
    self.shortBreakColor = [NSKeyedUnarchiver unarchiveObjectWithData:[taskInfo valueForKey:kFLShortBreakColor]];
    self.longBreakColor = [NSKeyedUnarchiver unarchiveObjectWithData:[taskInfo valueForKey:kFLLongBreakColor]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[_fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 76.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSString *cellIdentifier = (indexPath.row %3 == 0) ? @"TaskCell2" : @"TaskCell";

    static NSString *CellIdentifier = @"TaskCell";
    
    FLTaskCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    [self configureCell:cell atIndexPath:indexPath];
    
    cell.delegate = self;
    
    //configure left buttons
    cell.leftButtons = @[[MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"edit.png"] backgroundColor:[UIColor colorWithRed:1.0 green:149/255.0 blue:0.05 alpha:1.0] padding:25]];
    cell.leftSwipeSettings.transition = MGSwipeTransitionDrag;
    cell.leftExpansion.buttonIndex = 0;
//    cell.leftExpansion.fillOnTrigger = YES;
    
    //configure right buttons
    cell.rightButtons = @[[MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"delete.png"] backgroundColor:[UIColor redColor] padding:25]];
    cell.rightSwipeSettings.transition = MGSwipeTransitionDrag;
    cell.rightExpansion.buttonIndex = 0;
//    cell.rightExpansion.fillOnTrigger = YES;
    
    return cell;
}

- (void)configureCell:(FLTaskCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Task *task = [_fetchedResultsController objectAtIndexPath:indexPath];
//    cell.textLabel.text = task.name;
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld minutes task / %ld minutes break", (long) [task.taskTime integerValue], (long)[task.shortBreakTime integerValue]];
    cell.taskNameLabel.text = task.name;
    cell.cycleCountLabel.text = [NSString stringWithFormat:@"%@ Cycles", task.repeatCount];
    cell.taskTimeLabel.text = [NSString stringWithFormat:@"%d", [task.taskTime intValue]/ 60];
    cell.totalTimeLabel.text = [self stringifyTotalTime:([task.taskTime intValue] * [task.repeatCount intValue]) usingLongFormat:YES];
    
//    cell.reminderDateLabel.text = (indexPath.row % 3 == 0) ? @"26 May 2015 6:00 pm" : nil;
    cell.reminderDateLabel.text = [self.formatter stringFromDate:task.reminderDate];
    cell.taskColorView.backgroundColor = task.taskColor;
    
    if (![task.isSelected boolValue]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

#pragma mark - TableView Delegate methods.

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.taskTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSLog(@"Row: %li - %@", (long)indexPath.row, cell.textLabel.text);
    
    Task *newTask = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    if (![newTask.isSelected boolValue]) {
        //
        /* Check if the timer is running. If so add an Alert to let the customer know that the selecting the task will Stop previous task timer */
        //

        //Get currently selected task.
        Task *oldTask = [self currentSelectedTask];
        
        if (!oldTask) {
            newTask.isSelected = @YES;
            NSLog(@"No task was selected. It is a new task.");
        } else {
            oldTask.isSelected = @NO;
            newTask.isSelected = @YES;
            NSLog(@"Old task selection is replaced with new selection");
        }
        
        [self saveContext];
        
        self.taskName = newTask.name;
        self.taskTime = [newTask.taskTime integerValue];
        self.shortBreakTime = [newTask.shortBreakTime integerValue];
        self.longBreakTime = [newTask.longBreakTime integerValue];
        self.repeatCount = [newTask.repeatCount integerValue];
        self.longBreakDelay = [newTask.longBreakDelay integerValue];
        self.taskColor = newTask.taskColor;
        self.shortBreakColor = newTask.shortBreakColor;
        self.longBreakColor = newTask.longBreakColor;
        
        self.taskTitleLabel.text = newTask.name;

//        if ([self backupExist]) {
//            [self removeTaskInfoBackup];
//        }
        
        [self backUpTaskInfo];
        
        [self.repeatTimer resetTimer]; // Stops previous task without saving the event details.
        [self repeatTimerSetup];
    } else {
        NSLog(@"Same task selected");
        [self closeListView];
    }
}

- (Task *)currentSelectedTask
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    request.predicate = [NSPredicate predicateWithFormat:@"isSelected == YES"];
    
    NSError *error = nil;
    NSArray *tasks = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    return [tasks lastObject];
}

- (void)saveContext
{
    NSError *error = nil;
    if ([self.managedObjectContext hasChanges]) {
        NSLog(@"Context changed");
        if (![self.managedObjectContext save:&error]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                            message:NSLocalizedString(@"Error in saving new task", @"Error in saving new task")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}

#pragma mark - MGSwipeTableCell elegate method.

-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell tappedButtonAtIndex:(NSInteger) index direction:(MGSwipeDirection)direction fromExpansion:(BOOL) fromExpansion
{
    NSLog(@"Delegate: button tapped, %@ position, index %d, from Expansion: %@",
          direction == MGSwipeDirectionLeftToRight ? @"left" : @"right", (int)index, fromExpansion ? @"YES" : @"NO");
    
    // Delete button
    if (direction == MGSwipeDirectionRightToLeft && index == 0) {
        NSIndexPath * path = [self.taskTableView indexPathForCell:cell];
        NSManagedObjectContext *context = [self managedObjectContext];
        Task *taskToDelete = [_fetchedResultsController objectAtIndexPath:path];
        
        // Check the task to be deleted is currently selected task. If so reset all timer info related to the task.
        if ([taskToDelete.isSelected boolValue]) {
            if (!self.repeatTimer.isRunning) {
                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSLog(@"Cancel Reminder notifications while task is Paused");
                    [self cancelReminderNotificationForTask:taskToDelete];
                });
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSLog(@"Cancel All notifications related to the task");
                    [self cancelAllNotificationsForTask:taskToDelete];
                });
            }
            [self resetTaskTimer];
        } else {
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"Cancel Reminder notifications for the task");
                [self cancelReminderNotificationForTask:taskToDelete];
            });
        }
        
        [context deleteObject:taskToDelete];
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Error! %@", error);
        }
    }
    
    // Edit button
    if (direction == MGSwipeDirectionLeftToRight && index == 0) {
        NSIndexPath * path = [self.taskTableView indexPathForCell:cell];
        Task *task = [_fetchedResultsController objectAtIndexPath:path];
        self.isTaskEditing = YES;
        
        [self performSegueWithIdentifier:@"EditTaskSegue" sender:task];
    }
    
    return YES;
}

#pragma mark - Fetched Results Controller Section

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Task" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // adding predicate to avoid appearing new rows while pressing Add task button.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K != %@", @"name", nil];
    [fetchRequest setPredicate:predicate];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    fetchRequest.sortDescriptors = sortDescriptors;
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:context
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil];
    _fetchedResultsController.delegate = self;
    return _fetchedResultsController;
}

#pragma mark - Fetched Results Controller Delegates

// Return AppDelegate's ManagedObjectContext.
-(NSManagedObjectContext *)managedObjectContext
{
    return [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.taskTableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.taskTableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.taskTableView;
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            NSLog(@"Inserting");
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            NSLog(@"Deleting");
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            NSLog(@"Updating");
            [self configureCell:(FLTaskCell *)[self.taskTableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
//            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
//            [tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        case NSFetchedResultsChangeMove:
            NSLog(@"Moving");
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationRight];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.taskTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.taskTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
            break;
    }
}

#pragma mark - Reset Task Timer
- (void)resetTaskTimer
{
    // Deletes without calling TaskFinished Delegate.
    [self.repeatTimer resetTimer];
    
    if ([self backupExist]) {
        [self removeTaskInfoBackup];
    }
    
    self.taskName = @"";
    self.taskTime = 0;
    self.shortBreakTime = 0;
    self.longBreakTime = 0;
    self.repeatCount = 0;
    self.longBreakDelay = 0;
    
    [self repeatTimerSetup];
    
    self.taskTitleLabel.text = @"";
}

#pragma mark - Edit the task method

- (IBAction)editTask:(id)sender
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    request.predicate = [NSPredicate predicateWithFormat:@"isSelected == YES"];
    
    Task *task;
    NSError *error = nil;
    NSArray *tasks = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if ([tasks count] == 0) {
        NSLog(@"Could not find task details! Check the details");
    } else if ([tasks count] == 1){
       task = [tasks lastObject];
    } else {
        NSLog(@"Multple tasks selected, Something wrong");
    }

    self.isTaskEditing = YES;
    
    [self performSegueWithIdentifier:@"EditTaskSegue" sender:task];
}

#pragma mark - Add New task method

- (IBAction)addTask:(id)sender
{
    self.isTaskEditing = NO;
    [self performSegueWithIdentifier:@"EditTaskSegue" sender:nil];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"EditTaskSegue"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        FLEditTaskController *editTaskController = (FLEditTaskController *)navigationController.topViewController;
        editTaskController.delegate = self;
        editTaskController.task = sender;
        editTaskController.taskEditing = self.isTaskEditing;
    }
}

#pragma mark - FLTaskController delegate.

- (void)taskController:(FLEditTaskController *)controller didChangeTask:(Task *)task withTimerValue:(BOOL)changed
{
    NSLog(@"task delegate called");
    self.taskName = task.name;
    self.taskTime = [task.taskTime integerValue];
    self.shortBreakTime = [task.shortBreakTime integerValue];
    self.longBreakTime = [task.longBreakTime integerValue];
    self.repeatCount = [task.repeatCount integerValue];
    self.longBreakDelay = [task.longBreakDelay integerValue];
    self.taskColor = task.taskColor;
    self.shortBreakColor = task.shortBreakColor;
    self.longBreakColor = task.longBreakColor;
    
//    if ([self backupExist]) {
//        [self removeTaskInfoBackup];
//    }
    
    [self backUpTaskInfo];
    
    self.taskTitleLabel.text = task.name;
    
    if (changed) {
        [self resetTimer:nil];
        [self repeatTimerSetup];
    }
}

# pragma mark - Helper methods to convert Time & Date to String.

- (NSString *)getDateStringForTimeInterval:(NSTimeInterval)timeInterval
{
    return [self getDateStringForTimeInterval:timeInterval withDateFormatter:nil];
}

- (NSString *)getDateStringForTimeInterval:(NSTimeInterval )timeInterval withDateFormatter:(NSNumberFormatter *)formatter
{
    double hours;
    double minutes;
    double seconds = round(timeInterval);
    hours = floor(seconds / 3600.);
    seconds -= 3600. * hours;
    minutes = floor(seconds / 60.);
    seconds -= 60. * minutes;
    
    if (!formatter) {
        formatter = [[NSNumberFormatter alloc] init];
        [formatter setFormatterBehavior:NSNumberFormatterBehaviorDefault];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [formatter setMaximumFractionDigits:1];
        [formatter setPositiveFormat:@"#00"];  // Use @"#00.0" to display milliseconds as decimal value.
    }
    
    NSString *secondsInString = [formatter stringFromNumber:[NSNumber numberWithDouble:seconds]];
    
    if (hours == 0) {
        return [NSString stringWithFormat:NSLocalizedString(@"%02.0f:%@", @"Short format for elapsed time (minute:second). Example: 05:3.4"), minutes, secondsInString];
    } else {
        return [NSString stringWithFormat:NSLocalizedString(@"%.0f:%02.0f:%@", @"Short format for elapsed time (hour:minute:second). Example: 1:05:3.4"), hours, minutes, secondsInString];
    }
}

- (NSString *)dateStringForTimeIntervalWithoutHour:(NSTimeInterval )timeInterval withDateFormatter:(NSNumberFormatter *)formatter
{
    double minutes;
    double seconds = round(timeInterval);
    minutes = floor(seconds / 60.);
    seconds -= 60. * minutes;
    
    if (!formatter) {
        formatter = [[NSNumberFormatter alloc] init];
        [formatter setFormatterBehavior:NSNumberFormatterBehaviorDefault];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [formatter setMaximumFractionDigits:1];
        [formatter setPositiveFormat:@"#00"];  // Use @"#00.0" to display milliseconds as decimal value.
    }
    
    NSString *secondsInString = [formatter stringFromNumber:[NSNumber numberWithDouble:seconds]];
    
    return [NSString stringWithFormat:NSLocalizedString(@"%02.0f:%@", @"Short format for elapsed time (minute:second). Example: 05:3.4"), minutes, secondsInString];
}

- (NSString *)stringifyTotalTime:(int)seconds usingLongFormat:(BOOL)longFormat
{
    int remainingSeconds = seconds;
    
    int hours = remainingSeconds / 3600;
    
    remainingSeconds = remainingSeconds - hours * 3600;
    
    int minutes = remainingSeconds / 60;
    
    remainingSeconds = remainingSeconds - minutes * 60;
    
    if (longFormat) {
        if (hours > 0) {
            return [NSString stringWithFormat:@"%i hr %i min", hours, minutes];
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

@end
