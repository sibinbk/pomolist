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
#import "FLSettingsController.h"
#import "ZGCountDownTimer.h"
#import "Task.h"
#import "Event.h"
#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"
#import "JSQSystemSoundPlayer.h"
#import "UIColor+FlatColors.h"
#import "ColorUtils.h"
#import "FLTaskCell.h"
#import "UIScrollView+EmptyDataSet.h"
#import "SCLAlertView.h"

static NSString * const kFLScreenLockKey = @"kFLScreenLockKey";
static NSString * const kFLAlarmSoundKey = @"kFLAlarmSoundKey";

#define kFLTaskName                     @"taskName"
#define kFLTaskTime                     @"taskTime"
#define kFLShortBreakTime               @"shortBreakTime"
#define kFLLongBreakTime                @"longBreakTime"
#define kFLRepeatCount                  @"repeatCount"
#define kFLLongBreakDelay               @"longBreakDelay"
#define kFLTaskColorString              @"taskColorString"
#define kFLShortBreakColorString        @"shortBreakColorString"
#define kFLLongBreakColorString         @"longBreakColorString"

#define kFLUserDefaultKey               @"FocusListUserDefaults"
#define kFLRepeatTimer                  @"FLRepeatTimer"
#define kFLTimerNotification            @"FLTimerNotification"

@interface FLTimerViewController () <ZGCountDownTimerDelegate, FLTaskControllerDelegate, FLSettingsControllerDelegate, UITableViewDataSource, UITableViewDelegate, MGSwipeTableCellDelegate, NSFetchedResultsControllerDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource>

@property (nonatomic) NSTimeInterval taskTime;
@property (nonatomic) NSTimeInterval shortBreakTime;
@property (nonatomic) NSTimeInterval longBreakTime;
@property (nonatomic) NSTimeInterval totalCountDownTime;
@property (nonatomic) NSInteger repeatCount;
@property (nonatomic) NSInteger longBreakDelay;
@property (strong, nonatomic) NSString *taskName;
@property (strong, nonatomic) NSString *taskColorString;
@property (strong, nonatomic) NSString *shortBreakColorString;
@property (strong, nonatomic) NSString *longBreakColorString;
@property (strong, nonatomic) NSString *alarmSound;
@property (strong, nonatomic) UIFont *timerLabelFont;

/*
 @property (strong, nonatomic) NSDateFormatter *formatter;
 */

@property (assign, nonatomic) BOOL isFullView;
@property (assign, nonatomic) BOOL isTaskEditing;

@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (weak, nonatomic) IBOutlet UILabel *cycleLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTaskTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *sessionCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *listButton;
@property (weak, nonatomic) IBOutlet UIButton *eventListButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *timerViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *timerLabelSpacing;
@property (weak, nonatomic) IBOutlet UITableView *taskTableView;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *summaryView;
@property (strong, nonatomic) DesignableButton *floatingButton;

@property(strong, nonatomic) ZGCountDownTimer *repeatTimer;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@end

@implementation FLTimerViewController

@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Check if Back up task info is available.
    if ([self backupExist]) {
        [self restoreTaskInfo];
    } else {
        self.taskName = @"Pomodoro List";
        self.taskTime = 20;
        self.shortBreakTime = 15;
        self.longBreakTime = 20;
        self.repeatCount = 3;
        self.longBreakDelay = 2;
        self.taskColorString = @"E74C3C"; // Alizarin
        self.shortBreakColorString = @"2C3E50"; // Dark
        self.longBreakColorString = @"8E44AD"; // Purple
    }

    // Set Repeat timer.
    self.repeatTimer = [ZGCountDownTimer countDownTimerWithIdentifier:kFLRepeatTimer];
    self.repeatTimer.delegate = self;
    [self setUpRepeatTimer];
    
    // Read settings info from UserDefaults.
    [self restoreSettingsInfo];
    
    // Fetch Task list from CoreData.
    [self loadTaskListFromStore];

    // Set EmptyDataSet delegate & datasource.
    self.taskTableView.emptyDataSetSource = self;
    self.taskTableView.emptyDataSetDelegate = self;
    
    // A little trick for removing the cell separators
    self.taskTableView.tableFooterView = [UIView new];
    
    // Timerview handling.
    self.isFullView = YES;
    self.timerViewHeight.constant = CGRectGetHeight(self.view.frame);

    // Add Floating button to add new tasks.
    [self createAddTaskButton];
    
    // Adjust Timer label font size depends up on the device screen size.
    [self setUpTimerLabelFont];
    
    // Add Gesture recognizer to the timer view.
    [self setUpGestures];
    
    // Set TimerView Interface
    [self setUpTimerViewInterface];
    
    [[self.navigationController navigationBar] setBackgroundImage:[UIImage new]
                             forBarMetrics:UIBarMetricsDefault];
    [self.navigationController navigationBar].shadowImage = [UIImage new];
    [self.navigationController navigationBar].translucent = YES;
    
    /* Date formatter for reminder
     
     //Setup date formatter
     self.formatter = [[NSDateFormatter alloc] init];
     NSString *format = [NSDateFormatter dateFormatFromTemplate:@"MMM dd 'at' h:mm a" options:0 locale:[NSLocale currentLocale]];
     [self.formatter setDateFormat:format];
     */
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    self.navigationItem.title = self.taskName;

    self.timerLabel.font = self.timerLabelFont;
    
    if (self.isFullView) {
        self.floatingButton.hidden = YES;
    } else {
        self.floatingButton.hidden = NO;
    }
    
    [self.taskTableView reloadData];
}

#pragma mark - Repeat timer set up.

- (void)setUpRepeatTimer
{
    self.totalCountDownTime = [self calculateTotalCountDownTime:self.repeatCount];
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
}

- (NSTimeInterval)calculateTotalCountDownTime:(NSInteger)repeatCount
{
    int longBreakCount = 0;
    
    // No. of breaks will be always 1 less than task sessions.
    int totalBreakCount = (int)(repeatCount - 1);
    
    if (self.longBreakDelay > 0) {
        longBreakCount = totalBreakCount / self.longBreakDelay;
        NSLog(@"Long break count : %d", longBreakCount);
    }
    
    NSTimeInterval totalTime = (self.taskTime * repeatCount) + (self.longBreakTime * longBreakCount) + (self.shortBreakTime * (totalBreakCount - longBreakCount));
    NSLog(@"Total Time = %f", totalTime);
    
    return totalTime;
}

#pragma mark - Timer view UI set up.

- (void)setUpTimerViewInterface
{
    if (!self.repeatTimer.isRunning) {
        if (!self.repeatTimer.started) {
            self.resetButton.hidden = YES;
        } else {
            self.resetButton.hidden = NO;
        }
        
        [self.startButton setImage:[UIImage imageNamed:@"PlayFilled.png"] forState:UIControlStateNormal];
        
        // Chcek if it fullview before un-hiding the skip button.
        if (![self isFullView]) {
            self.skipButton.hidden = YES;
        } else {
            self.skipButton.hidden = NO;
        }
    } else {
        [self.startButton setImage:[UIImage imageNamed:@"PauseFilled.png"] forState:UIControlStateNormal];
        self.resetButton.hidden = NO;
        self.skipButton.hidden = YES;
    }
}

#pragma mark - Timer Label Font size setter method.

- (void)setUpTimerLabelFont
{
    if ([[UIScreen mainScreen] bounds].size.height == 480) {
        // iPhone 4
        self.timerLabelFont = [self.timerLabel.font fontWithSize:80];
    } else if ([[UIScreen mainScreen] bounds].size.height == 568){
        // IPhone 5
        self.timerLabelFont = [self.timerLabel.font fontWithSize:80];
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) {
        // iPhone 6
        self.timerLabelFont = [self.timerLabel.font fontWithSize:100];
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) {
        // iPhone 6+
        self.timerLabelFont = [self.timerLabel.font fontWithSize:110];
    } else {
        // iPad
        self.timerLabelFont = [self.timerLabel.font fontWithSize:120];
    }
}

#pragma mark - Floating button for adding new task.

- (void)createAddTaskButton
{
    self.floatingButton = [[DesignableButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)/2 - 30, CGRectGetHeight(self.view.frame) - 80 , 60, 60)];
    self.floatingButton.cornerRadius = 30;
    self.floatingButton.backgroundColor = [UIColor flatPeterRiverColor];
    self.floatingButton.shadowColor = [UIColor grayColor];
    self.floatingButton.shadowRadius = 2;
    self.floatingButton.shadowOffsetY = 1;
    self.floatingButton.shadowOpacity = 3;
    [self.floatingButton setImage:[UIImage imageNamed:@"plus"] forState:UIControlStateNormal];
    [self.floatingButton addTarget:self action:@selector(addNewTask) forControlEvents:UIControlEventTouchUpInside];
    self.floatingButton.hidden = YES;
    [self.view addSubview:self.floatingButton];
}

#pragma mark - Gestures for animation

- (void)setUpGestures
{
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showListView)];
    [swipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
    [self.mainView addGestureRecognizer:swipeUp];
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeListView)];
    [swipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.mainView addGestureRecognizer:swipeDown];
    
    // Adds gesture recognizers to navigation bar.
    UISwipeGestureRecognizer *navSwipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showListView)];
    [navSwipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
    [[self.navigationController navigationBar] addGestureRecognizer:navSwipeUp];
    
    UISwipeGestureRecognizer *navSwipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeListView)];
    [navSwipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
    [[self.navigationController navigationBar] addGestureRecognizer:navSwipeDown];
}

# pragma mark - View handling methods.

- (void)closeListView
{
    [self.view setNeedsUpdateConstraints];
    self.timerViewHeight.constant = CGRectGetHeight(self.view.frame);
    self.timerLabelSpacing.constant = 0.0f;
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
        self.timerLabel.font = self.timerLabelFont;
        self.floatingButton.hidden = YES;
    } completion:^(BOOL finished) {
        self.startButton.hidden = NO;
        self.navigationItem.title = self.taskName;
        self.cycleLabel.hidden = NO;
        self.sessionCountLabel.hidden = NO;
        self.totalTaskTimeLabel.hidden = NO;
        self.summaryView.hidden = NO;
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
    [self.listButton setImage:[UIImage imageNamed:@"menu.png"]];
}
- (void)showListView
{
    [self.view setNeedsUpdateConstraints];
    self.timerViewHeight.constant = 64;
    self.timerLabelSpacing.constant = 20.0f;
    self.startButton.hidden = YES;
    self.resetButton.hidden = YES;
    self.skipButton.hidden = YES;
    self.editButton.hidden = YES;
    self.eventListButton.hidden = YES;
    self.navigationItem.title = @"";
    self.cycleLabel.hidden = YES;
    self.sessionCountLabel.hidden = YES;
    self.totalTaskTimeLabel.hidden = YES;
    self.summaryView.hidden = YES;
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
                         self.floatingButton.hidden = NO;
                         self.timerLabel.font = [self.timerLabel.font fontWithSize:40];
                     } completion:NULL];
    self.isFullView = NO;
    [self.listButton setImage:[UIImage imageNamed:@"delete.png"]];
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
        [self.startButton setImage:[UIImage imageNamed:@"PauseFilled.png"] forState:UIControlStateNormal];
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
            self.resetButton.hidden = YES;
        } else {
            self.resetButton.hidden = NO;
        }
        
        [self.startButton setImage:[UIImage imageNamed:@"PlayFilled.png"] forState:UIControlStateNormal];
        
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
    
    //GCD to avoid blocking UI while cancelling local notifications. Required only when Reminder notifications are available.
    if (self.repeatTimer.isRunning) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"Cancel Timer notification during reset");
            [self cancelTimerNotifications];
        });
    }

    [self.repeatTimer stopCountDown];
    
    NSLog(@"Stopss");
    [self.startButton setImage:[UIImage imageNamed:@"PlayFilled.png"] forState:UIControlStateNormal];
    self.resetButton.hidden = YES;
    self.skipButton.hidden = NO;
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
    
    // Make Reset button visible if the timer started.
    self.resetButton.hidden = !self.repeatTimer.started;
}

#pragma mark - schedule local notifications.

- (void)scheduleTimerNotifications
{
    NSTimeInterval tempCycleFinishTime = self.repeatTimer.cycleFinishTime;  // Total session times added upto current session.
    NSTimeInterval timePassed = self.repeatTimer.timePassed;
    CountDownCycleType cycleType = self.repeatTimer.cycleType;
   
    int taskCount = (int)self.repeatTimer.taskCount;            // No. of completed task sessions.
    int cycleCount = (int)self.repeatTimer.timerCycleCount;     // Total no. of completed sessions.
    int totalSessionCount = (int)((2 * self.repeatCount) - 1);
    
    int notificationCount = totalSessionCount - cycleCount;
    
    for (int i = 0; i < notificationCount; i++) {

        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.soundName = [NSString stringWithFormat:@"%@.caf", self.alarmSound];
        notification.userInfo = @{@"timerNotificationID" : kFLTimerNotification};

        switch (cycleType) {
            case TaskCycle:
                notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:(tempCycleFinishTime - timePassed)];
                notification.alertBody = [NSString stringWithFormat:@"Pomodoro %d completed. Take a break! - Goal %d/%d", taskCount, taskCount, (int)self.repeatCount] ;
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
    
    UILocalNotification *finalNotification = [[UILocalNotification alloc] init];
    finalNotification.timeZone = [NSTimeZone systemTimeZone];
    finalNotification.soundName = [NSString stringWithFormat:@"%@.caf", self.alarmSound];
    finalNotification.userInfo = @{@"timerNotificationID" : kFLTimerNotification};
    finalNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:(self.totalCountDownTime - timePassed)];
    finalNotification.alertBody = [NSString stringWithFormat:@"Well done. Task completed! - Goal %d/%d", taskCount, (int)self.repeatCount];
    [[UIApplication sharedApplication] scheduleLocalNotification:finalNotification];
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

/* Reminder notification.
 
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

*/

#pragma mark - cancel local notifications.

- (void)cancelTimerNotifications
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

/* Reminde notification cancelling code.
 
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
*/

# pragma mark - Change notification sound.

- (void)changeNotificationSound:(NSString *)sound
{
    NSArray *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    for (UILocalNotification *notification in notifications) {
        notification.soundName = [NSString stringWithFormat:@"%@.caf", sound];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        NSLog(@"Notification changed");
    }
}

#pragma mark - ZGCountDownTimer Delegate methods.

- (void)secondUpdated:(ZGCountDownTimer *)sender countDownTimePassed:(NSTimeInterval)timePassed ofTotalTime:(NSTimeInterval)totalTime
{
    // Conversion to Time string without hour component.
    self.timerLabel.text = [self dateStringForTimeIntervalWithoutHour:(totalTime - timePassed) withDateFormatter:nil];
}

- (void)sessionChanged:(CountDownCycleType)cycle completedTask:(NSInteger)completedCount ofTotalTask:(NSInteger)count withTotalTime:(NSTimeInterval)time
{
    NSString *viewColorString;
    NSString *cycleTitle;
    
    switch (cycle) {
        case TaskCycle:
            cycleTitle = [NSString stringWithFormat:@"Pomodoro # %ld", (long) count];
            viewColorString = self.taskColorString;
            break;
        case ShortBreakCycle:
            cycleTitle = @"Short Break";
            viewColorString = self.shortBreakColorString;
            break;
        case LongBreakCycle:
            cycleTitle = @"Long Break";
            viewColorString = self.longBreakColorString;
            break;
        default:
            break;
    }
    
    self.cycleLabel.text = cycleTitle;
    self.sessionCountLabel.text = [NSString stringWithFormat:@"%ld/%ld", (long)completedCount, (long)self.repeatCount];
    self.totalTaskTimeLabel.text = [self stringifyTotalTime:(int)time usingLongFormat:NO];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.mainView.backgroundColor = [UIColor colorWithString:viewColorString];
    }];

}

- (void)taskFinished:(ZGCountDownTimer *)sender totalTaskTime:(NSTimeInterval)time sessionCount:(NSInteger)count
{
    SCLAlertView *alert = [[SCLAlertView alloc] init];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"TASK FINISHED");
        self.resetButton.hidden = YES;
        self.skipButton.hidden = NO;
        // Set start button title to 'START' after finishing timer.
        [self.startButton setImage:[UIImage imageNamed:@"PlayFilled.png"] forState:UIControlStateNormal];
        // Show task completion alert.
        [alert showSuccess:self title:@"Well Done" subTitle:@"Task completed" closeButtonTitle:@"Done" duration:0.0f];
    });
    
    // Save event info if atleast one session is completed.
    if (count > 0) {
        [self saveEventOfTask:[self currentSelectedTask] withTotalTime:time sessionCount:count];
    }
}

- (void)taskSessionCompleted:(ZGCountDownTimer *)sender
{
    [self playAlertSound:self.alarmSound];
}

- (void)shortBreakCompleted:(ZGCountDownTimer *)sender
{
    [self playAlertSound:self.alarmSound];
}

- (void)longBreakCompleted:(ZGCountDownTimer *)sender
{
    [self playAlertSound:self.alarmSound];
}

#pragma mark - JSQSystemSound player methods.

- (void)playAlertSound:(NSString *)sound
{
    [[JSQSystemSoundPlayer sharedPlayer] playAlertSoundWithFilename:sound
                                                      fileExtension:kJSQSystemSoundTypeCAF
                                                         completion:nil];
}

#pragma mark - Save Task event method.

- (void)saveEventOfTask:(Task *)task withTotalTime:(NSTimeInterval)totalTime sessionCount:(NSInteger)count
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSEntityDescription *eventEntity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:context];
    
    //Initialize Event.
    Event *event = [[Event alloc] initWithEntity:eventEntity insertIntoManagedObjectContext:context];
    
    //Populate Event details.
    event.finishDate = [NSDate date];
    event.totalTaskTime = [NSNumber numberWithDouble:totalTime];
    event.totalSessionCount = [NSNumber numberWithInteger:count];
    
    [task addEventsObject:event];
    
    [self saveContext];
}

#pragma mark - backup/restore methods

- (void)restoreSettingsInfo
{
    NSNumber *screenLockStatus = [[NSUserDefaults standardUserDefaults] objectForKey:kFLScreenLockKey];
    NSString *alarmSound = [[NSUserDefaults standardUserDefaults] objectForKey:kFLAlarmSoundKey];
    
    if (!screenLockStatus) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    } else {
        [[UIApplication sharedApplication] setIdleTimerDisabled:[screenLockStatus boolValue]];
    }
    
    if (!alarmSound) {
        self.alarmSound = @"RingRing";
    } else {
        self.alarmSound = alarmSound;
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
             kFLTaskColorString: self.taskColorString,
             kFLShortBreakColorString: self.shortBreakColorString,
             kFLLongBreakColorString: self.longBreakColorString
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
    self.taskColorString = [taskInfo valueForKey:kFLTaskColorString];
    self.shortBreakColorString = [taskInfo valueForKey:kFLShortBreakColorString];
    self.longBreakColorString = [taskInfo valueForKey:kFLLongBreakColorString];
}

#pragma mark - Empty Dataset data source.

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"Checkmark"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Task List is empty!";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Add a new task to start using Listee.";
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0f]};
    
    return [[NSAttributedString alloc] initWithString:@"Continue" attributes:attributes];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor whiteColor];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return -self.taskTableView.tableHeaderView.frame.size.height/2.0f;
}

#pragma mark - Empty Dataset delegate.

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView
{
    return YES;
}

- (BOOL)emptyDataSetShouldAllowTouch:(UIScrollView *)scrollView
{
    return YES;
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView
{
    return YES;
}

- (void)emptyDataSetDidTapButton:(UIScrollView *)scrollView
{
    // Do something
    NSLog(@"Empty dataset button pressed");
}

#pragma mark - Fetched results controller performFetch method.

- (void)loadTaskListFromStore
{
    NSError *error = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error in loading data", @"Error in loading data")
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Error was: %@, quitting.", @"Error was: %@, quitting."), [error localizedDescription]]
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                              otherButtonTitles:nil];
        [alert show];
    }
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
    return 70.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSString *cellIdentifier = (indexPath.row %3 == 0) ? @"TaskCell2" : @"TaskCell";

    static NSString *CellIdentifier = @"TaskCell";
    
    FLTaskCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    [self configureCell:cell atIndexPath:indexPath];
    
    cell.delegate = self;
    
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
    
/*  reminder label.
 cell.reminderDateLabel.text = [self.formatter stringFromDate:task.reminderDate];
 */
    cell.taskColorView.backgroundColor = [UIColor colorWithString:task.taskColorString];
    
    if (![task.isSelected boolValue]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
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
        
        if (self.repeatTimer.isRunning) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"Cancel Timer notifications related to the task");
                [self cancelTimerNotifications];
            });
        }

        //Get currently selected task.
        Task *currentTask = [self currentSelectedTask];
        
        if (!currentTask) {
            newTask.isSelected = @YES;
            NSLog(@"No task was selected. It is a new task.");
        } else {
            currentTask.isSelected = @NO;
            newTask.isSelected = @YES;
            NSLog(@"Old task selection is replaced with new selection");
        }
        
        // Change and save new task details.
        [self changeTaskDetails:newTask];

        if (self.isFullView) {
            self.navigationItem.title = newTask.name;
        } else {
            self.navigationItem.title = @"";
        }
        
        // Store selected task info.
        [self saveContext];
        
        [self.repeatTimer resetTimer]; // Stops previous task without saving the event details.
        [self setUpRepeatTimer];
        [self setUpTimerViewInterface];
//        [self closeListView];
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

- (void)changeTaskDetails:(Task *)task
{
    self.taskName = task.name;
    self.taskTime = [task.taskTime integerValue];
    self.shortBreakTime = [task.shortBreakTime integerValue];
    self.longBreakTime = [task.longBreakTime integerValue];
    self.repeatCount = [task.repeatCount integerValue];
    self.longBreakDelay = [task.longBreakDelay integerValue];
    self.taskColorString = task.taskColorString;
    self.shortBreakColorString = task.shortBreakColorString;
    self.longBreakColorString = task.longBreakColorString;
    
    [self backUpTaskInfo];
}

#pragma mark - Coredata Context save method.

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
 
    /* Cancelling Local notifications when the task is deleted.
     
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
     */
        
        // Check the task to be deleted is currently selected task. If so reset all timer info related to the task.
        if ([taskToDelete.isSelected boolValue]) {
            if (self.repeatTimer.isRunning) {
                 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSLog(@"Cancel Timer notifications related to the task");
                    [self cancelTimerNotifications];
                });
            }
            
            [self resetTaskTimer];
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
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
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

#pragma mark - Resets Task Timer upon task deletion.

- (void)resetTaskTimer
{
    // Resets timer without calling TaskFinished Delegate when a running task is deleted.
    
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
    
    [self setUpRepeatTimer];
    
    [self setUpTimerViewInterface];
    
    self.navigationItem.title = @"Pomo List";
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

- (void)addNewTask
{
    self.isTaskEditing = NO;
    [self performSegueWithIdentifier:@"EditTaskSegue" sender:nil];
}

#pragma mark - Segue handling methods.

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"EditTaskSegue"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        FLEditTaskController *editTaskController = (FLEditTaskController *)navigationController.topViewController;
        editTaskController.delegate = self;
        editTaskController.task = sender;
        editTaskController.taskEditing = self.isTaskEditing;
    }
    
    if ([segue.identifier isEqualToString:@"SettingsSegue"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        FLSettingsController *settingsController = (FLSettingsController *)navigationController.topViewController;
        settingsController.delegate = self;
        settingsController.alarmSound = self.alarmSound;
    }
}

#pragma mark - FLTaskController delegate.

- (void)taskController:(FLEditTaskController *)controller didChangeTask:(Task *)task withTimerValue:(BOOL)changed
{
    NSLog(@"task delegate called");
    
    [self changeTaskDetails:task];
    
    self.navigationItem.title = task.name;
    
    if (changed) {
        [self.repeatTimer resetTimer];
        [self setUpRepeatTimer];
        [self setUpTimerViewInterface];
    }
}

#pragma mark - FLSettingsController delegate.

- (void)settingsController:(FLSettingsController *)controller didChangeAlarmSound:(NSString *)sound
{
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    if (![self.alarmSound isEqualToString:sound]) {
        self.alarmSound = sound;
        
        // Change notifications sound.
        [self changeNotificationSound:sound];
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
            return [NSString stringWithFormat:@"%ih %im", hours, minutes];
        } else {
            return [NSString stringWithFormat:@"%im", minutes];
        }
    }
}

@end
