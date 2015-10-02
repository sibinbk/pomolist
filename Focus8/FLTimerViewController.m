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
#import "JTHamburgerButton.h"
#import "CNPPopupController.h"

static NSString * const kFLScreenLockKey = @"kFLScreenLockKey";
static NSString * const kFLAlarmSoundKey = @"kFLAlarmSoundKey";

static NSString * const kFLTaskName = @"taskName";
static NSString * const kFLTaskTime = @"taskTime";
static NSString * const kFLShortBreakTime = @"shortBreakTime";
static NSString * const kFLLongBreakTime = @"longBreakTime";
static NSString * const kFLRepeatCount = @"repeatCount";
static NSString * const kFLLongBreakDelay = @"longBreakDelay";
static NSString * const kFLTaskColorString = @"taskColorString";
static NSString * const kFLShortBreakColorString = @"shortBreakColorString";
static NSString * const kFLLongBreakColorString = @"longBreakColorString";

static NSString * const kFLUserDefaultKey = @"FocusListUserDefaults";
static NSString * const kFLRepeatTimer = @"FLRepeatTimer";
static NSString * const kFLTimerNotification = @"FLTimerNotification";
static NSString *const kFLAppTitle = @"Listie";

@interface FLTimerViewController () <ZGCountDownTimerDelegate, FLTaskControllerDelegate, FLSettingsControllerDelegate, UITableViewDataSource, UITableViewDelegate, MGSwipeTableCellDelegate, NSFetchedResultsControllerDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, CNPPopupControllerDelegate>

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
@property (assign, nonatomic) BOOL taskSelected;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (weak, nonatomic) IBOutlet UILabel *subTimerLabel;
@property (weak, nonatomic) IBOutlet UILabel *cycleLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTaskTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *sessionCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *eventListButton;
@property (weak, nonatomic) IBOutlet UILabel *editButtonLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventListButtonLabel;
@property (weak, nonatomic) IBOutlet UITableView *taskTableView;
@property (weak, nonatomic) IBOutlet UIView *summaryView;
@property (strong, nonatomic) DesignableButton *floatingButton;
@property (strong, nonatomic) JTHamburgerButton *listButton;
@property (strong, nonatomic) CNPPopupController *popupController;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *timerViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *summaryViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *startButtonHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subTimerLabelPosition;

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
        self.isFullView = YES;
        self.taskSelected = YES;
    } else {
        self.isFullView = NO;
        self.taskSelected = NO;
        self.taskName = @"";
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
    
    // Add animating List view button.
    [self listAllTasksButtonSetup];
    
    // Add Floating button to add new tasks.
    [self createAddTaskButton];
    
    // Adjust Timer label font size depends up on the device screen size.
    [self setUpFontAndViewLayout];
    
    // Add Gesture recognizer to the timer view.
    [self setUpGestures];
    
    // Set TimerView Interface
    [self setUpTimerViewInterfaceWith:self.isFullView];
    
    // Make navigation bar transparent and set custom font for title.
    [[self.navigationController navigationBar] setBackgroundImage:[UIImage new]
                             forBarMetrics:UIBarMetricsDefault];
    [self.navigationController navigationBar].shadowImage = [UIImage new];
    [self.navigationController navigationBar].translucent = YES;
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.6];
    shadow.shadowOffset = CGSizeMake(2, 2);
    [self.navigationController.navigationBar setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                                      [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                                      shadow, NSShadowAttributeName,
                                                                      [UIFont fontWithName:@"HelveticaNeue-Bold" size:32.0], NSFontAttributeName, nil]];
    
    // Setting Summary view blur effect.
    self.summaryView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
    
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

    // Assign Timer label font.
    self.timerLabel.font = self.timerLabelFont;
    
    if (self.isFullView) {
        [self.listButton setCurrentMode:JTHamburgerButtonModeHamburger];
    } else {
        [self.listButton setCurrentMode:JTHamburgerButtonModeCross];
        if (!self.taskSelected) {
            self.subTimerLabel.hidden = YES;
            self.navigationItem.title = kFLAppTitle;
        } else {
            self.navigationItem.title = @"";
            self.subTimerLabel.hidden = NO;
        }
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

- (void)setUpTimerViewInterfaceWith:(BOOL)fullView;
{
    // Setting task title.
    self.titleLabel.text = self.taskName;
    
    if (fullView) {
        self.navigationItem.title = @"";
        self.timerViewHeight.constant = CGRectGetHeight(self.view.frame);
        self.subTimerLabelPosition.constant = -60;
        
        if (!self.repeatTimer.isRunning) {
            [self.startButton setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
            self.resetButton.hidden = self.repeatTimer.started ? NO : YES;
            self.skipButton.hidden = NO;
        } else {
            [self.startButton setImage:[UIImage imageNamed:@"Pause.png"] forState:UIControlStateNormal];
            self.resetButton.hidden = NO;
            self.skipButton.hidden = YES;
        }
    } else {
        self.timerViewHeight.constant = 64;
        self.subTimerLabelPosition.constant = 18;
        self.titleLabel.hidden = YES;
        self.cycleLabel.hidden = YES;
        self.titleLabel.hidden = YES;
        self.startButton.hidden = YES;
        self.resetButton.hidden = YES;
        self.skipButton.hidden = YES;
        self.editButton.hidden = YES;
        self.eventListButton.hidden = YES;
        self.editButtonLabel.hidden = YES;
        self.eventListButtonLabel.hidden = YES;
        self.summaryView.hidden = YES;
        self.floatingButton.hidden = NO;
        
        if (!self.taskSelected) {
            self.subTimerLabel.hidden = YES;
            self.navigationItem.title = kFLAppTitle;
        } else {
            self.navigationItem.title = @"";
            self.subTimerLabel.hidden = NO;
        }

        if (!self.repeatTimer.isRunning) {
            [self.startButton setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
        } else {
            [self.startButton setImage:[UIImage imageNamed:@"Pause.png"] forState:UIControlStateNormal];
        }
    }
}

#pragma mark - Timer Label Font size setter method.

- (void)setUpFontAndViewLayout
{
    if ([[UIScreen mainScreen] bounds].size.height == 480) {
        // iPhone 4
        self.timerLabelFont = [self.timerLabel.font fontWithSize:80];
        self.summaryViewHeight.constant = 70;
        self.startButtonHeight.constant = 70;
        self.startButton.layer.cornerRadius = 35;
    } else if ([[UIScreen mainScreen] bounds].size.height == 568){
        // IPhone 5
        self.timerLabelFont = [self.timerLabel.font fontWithSize:80];
        self.summaryViewHeight.constant = 80;
        self.startButtonHeight.constant = 80;
        self.startButton.layer.cornerRadius = 40;
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) {
        // iPhone 6
        self.timerLabelFont = [self.timerLabel.font fontWithSize:110];
        self.summaryViewHeight.constant = 100;
        self.startButtonHeight.constant = 100;
        self.startButton.layer.cornerRadius = 50;
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) {
        // iPhone 6+
        self.timerLabelFont = [self.timerLabel.font fontWithSize:110];
        self.summaryViewHeight.constant = 110;
        self.startButtonHeight.constant = 100;
        self.startButton.layer.cornerRadius = 50;
    } else {
        // iPad
        self.timerLabelFont = [self.timerLabel.font fontWithSize:120];
        self.summaryViewHeight.constant = 120;
    }
}

#pragma mark - Animating menu button.

- (void)listAllTasksButtonSetup
{
    self.listButton = [[JTHamburgerButton alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
    self.listButton.lineSpacing = 6.0;
    [self.listButton updateAppearance];
    [self.listButton addTarget:self action:@selector(listButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.listButton];
    self.navigationItem.leftBarButtonItem.style = UIBarButtonItemStyleDone;
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
    UISwipeGestureRecognizer *swipeUpGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUp)];
    [swipeUpGesture setDirection:UISwipeGestureRecognizerDirectionUp];
    [self.mainView addGestureRecognizer:swipeUpGesture];
    
    UISwipeGestureRecognizer *swipeDownGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown)];
    [swipeDownGesture setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.mainView addGestureRecognizer:swipeDownGesture];
    
    // Adds gesture recognizers to navigation bar.
    UISwipeGestureRecognizer *navSwipeUpGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUp)];
    [navSwipeUpGesture setDirection:UISwipeGestureRecognizerDirectionUp];
    [[self.navigationController navigationBar] addGestureRecognizer:navSwipeUpGesture];
    
    UISwipeGestureRecognizer *navSwipeDownGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown)];
    [navSwipeDownGesture setDirection:UISwipeGestureRecognizerDirectionDown];
    [[self.navigationController navigationBar] addGestureRecognizer:navSwipeDownGesture];
}

- (void)swipeUp
{
    if (self.isFullView) {
        [self showListView];
    }
}

- (void)swipeDown
{
    if (!self.isFullView) {
        if (self.taskSelected) {
            [self closeListView];
        } else {
            SCLAlertView *resetAlert = [[SCLAlertView alloc] init];
            
            resetAlert.showAnimationType = SlideInToCenter;
            resetAlert.hideAnimationType = SlideOutToCenter;
            resetAlert.customViewColor = [UIColor flatAlizarinColor];
            [resetAlert removeTopCircle];
            
            [resetAlert showInfo:self.navigationController title:@"Task not selected!" subTitle:@"Please select a task from the list" closeButtonTitle:@"OK" duration:0.0f];
        }
        
    }
}

- (void)listButtonPressed:(id)sender
{
    if (![self isFullView]) {
        if (self.taskSelected) {
            [self closeListView];
        } else {
            SCLAlertView *resetAlert = [[SCLAlertView alloc] init];
            
            resetAlert.showAnimationType = SlideInToCenter;
            resetAlert.hideAnimationType = SlideOutToCenter;
            resetAlert.customViewColor = [UIColor flatAlizarinColor];
            [resetAlert removeTopCircle];
            
            [resetAlert showInfo:self.navigationController title:@"Task not selected!" subTitle:@"Please select a task from the list" closeButtonTitle:@"OK" duration:0.0f];
        }
    } else {
        [self showListView];
    }
}

# pragma mark - View handling methods.

- (void)closeListView
{
    self.navigationItem.title = @"";
    [self.listButton setCurrentModeWithAnimation:JTHamburgerButtonModeHamburger];
    self.isFullView = YES;
    self.listButton.enabled = NO;
    
    self.floatingButton.hidden = YES;
    self.titleLabel.hidden = NO;
    self.cycleLabel.hidden = NO;
    self.timerLabel.hidden = NO;
    self.startButton.hidden = NO;
    self.summaryView.hidden = NO;
    self.editButton.hidden = NO;
    self.eventListButton.hidden = NO;
    self.editButtonLabel.hidden = NO;
    self.eventListButtonLabel.hidden = NO;
    self.resetButton.hidden = self.repeatTimer.started ? NO : YES;
    self.skipButton.hidden = self.repeatTimer.isRunning ? YES : NO;

    self.subTimerLabel.alpha = 1;
    self.titleLabel.alpha = 0;
    self.cycleLabel.alpha = 0;
    self.timerLabel.alpha = 0;
    self.startButton.alpha = 0;
    self.resetButton.alpha = 0;
    self.skipButton.alpha = 0;
    self.summaryView.alpha = 0;
    self.editButton.alpha = 0;
    self.eventListButton.alpha = 0;
    self.editButtonLabel.alpha = 0;
    self.eventListButtonLabel.alpha = 0;
    [self.view setNeedsUpdateConstraints];
    self.timerViewHeight.constant = CGRectGetHeight(self.view.frame);
    self.subTimerLabelPosition.constant = -60;
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
        self.titleLabel.alpha = 1;
        self.cycleLabel.alpha = 1;
        self.timerLabel.alpha = 1;
        self.subTimerLabel.alpha = 0;
    } completion:^(BOOL finished) {
        self.subTimerLabel.hidden = YES;
        self.startButton.alpha = 1;
        self.resetButton.alpha = 1;
        self.skipButton.alpha = 1;
        self.summaryView.alpha = 1;
        self.editButton.alpha = 1;
        self.eventListButton.alpha = 1;
        self.editButtonLabel.alpha = 1;
        self.eventListButtonLabel.alpha = 1;

        self.listButton.enabled = YES;
    }];
}
- (void)showListView
{
    [self.listButton setCurrentModeWithAnimation:JTHamburgerButtonModeCross];
    self.isFullView = NO;
    self.listButton.enabled = NO;
    
    [self.view setNeedsUpdateConstraints];
    self.timerViewHeight.constant = 64;
    self.subTimerLabelPosition.constant = 18;
    
    self.startButton.hidden = YES;
    self.resetButton.hidden = YES;
    self.skipButton.hidden = YES;
    self.editButton.hidden = YES;
    self.eventListButton.hidden = YES;
    self.editButtonLabel.hidden = YES;
    self.eventListButtonLabel.hidden = YES;
    self.summaryView.hidden = YES;

    if (!self.taskSelected) {
        self.subTimerLabel.hidden = YES;
        self.navigationItem.title = kFLAppTitle;
    } else {
        self.navigationItem.title = @"";
        self.subTimerLabel.hidden = NO;
    }
    self.subTimerLabel.alpha = 1;

    self.floatingButton.hidden = NO;
    self.floatingButton.alpha = 0;
    
    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.7
                        options:0
                     animations:^{
                         [self.view layoutIfNeeded];
                         self.floatingButton.alpha = 1;
                         self.timerLabel.alpha = 0;
                         self.titleLabel.alpha = 0;
                         self.cycleLabel.alpha = 0;
                     } completion:^(BOOL finished) {
                         self.timerLabel.hidden = YES;
                         self.cycleLabel.hidden = YES;
                         self.titleLabel.hidden = YES;
                         self.listButton.enabled = YES;
                     }];
}

#pragma mark - Timer methods.

- (IBAction)startTimer:(id)sender
{
    if (!self.taskSelected) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Task not selected"
                                                                       message:@"Please select a task from the list"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                                  // Go back to list view.
                                                                  [self showListView];
                                                              }];
        [alert addAction:dismissAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    if (![self.repeatTimer isRunning]) {
        [self.repeatTimer startCountDown];
        [self.startButton setImage:[UIImage imageNamed:@"Pause.png"] forState:UIControlStateNormal];
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
        
        [self.startButton setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
        
        self.skipButton.hidden = NO;

        // GCD to avoid blocking UI while cancelling local notifications.
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"Cancel Timer notifications while Pause");
            [self cancelTimerNotifications];
        });
    }
}

- (IBAction)resetButtonPressed:(id)sender
{
    if (!self.taskSelected) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Task not selected"
                                                                       message:@"Please select a task from the list"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                                  // Go back to list view.
                                                                  [self showListView];
                                                              }];
        [alert addAction:dismissAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    SCLAlertView *resetAlert = [[SCLAlertView alloc] init];
    
    resetAlert.showAnimationType = SlideInToCenter;
    resetAlert.hideAnimationType = SlideOutToCenter;
    resetAlert.customViewColor = [UIColor flatAlizarinColor];
    
    [resetAlert addButton:@"Yes" actionBlock:^{
        [self resetTaskTimer];
    }];
    
    [resetAlert showNotice:self.navigationController title:@"Reset Timer" subTitle:@"Are you sure you want to reset timer?" closeButtonTitle:@"No" duration:0.0f];
}

- (void)resetTaskTimer
{
    //GCD to avoid blocking UI while cancelling local notifications. Required only when Reminder notifications are available.
    if (self.repeatTimer.isRunning) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"Cancel Timer notification during reset");
            [self cancelTimerNotifications];
        });
    }
    
    [self.repeatTimer stopCountDown];
    
    NSLog(@"Stopss");
    [self.startButton setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
    self.resetButton.hidden = YES;
    self.skipButton.hidden = NO;
}

- (IBAction)skipButtonPressed:(id)sender
{
    if (!self.taskSelected) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Task not selected"
                                                                       message:@"Please select a task from the list"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                                  // Go back to list view.
                                                                  [self showListView];
                                                              }];
        [alert addAction:dismissAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }

    SCLAlertView *resetAlert = [[SCLAlertView alloc] init];
    
    resetAlert.showAnimationType = SlideInToCenter;
    resetAlert.hideAnimationType = SlideOutToCenter;
    resetAlert.customViewColor = [UIColor flatAlizarinColor];
    
    [resetAlert addButton:@"Yes" actionBlock:^{
        [self skipTasktimer];
    }];
    
    [resetAlert showNotice:self.navigationController title:@"Skip Timer" subTitle:@"Are you sure you want to skip timer?" closeButtonTitle:@"No" duration:0.0f];

}

- (void)skipTasktimer
{
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
                notification.alertBody = [NSString stringWithFormat:@"Task Session %d completed. Take a break! - Goal %d sessions", taskCount, (int)self.repeatCount];
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
    finalNotification.alertBody = [NSString stringWithFormat:@"Well done. Task completed! - Goal %d sessions", (int)self.repeatCount];
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
    NSLog(@"Cancel Timer Notifications");
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
    NSString *timeString = [self dateStringForTimeIntervalWithoutHour:(totalTime - timePassed) withDateFormatter:nil];
    
    self.timerLabel.text = timeString;
    self.subTimerLabel.text = timeString;
}

- (void)sessionChanged:(CountDownCycleType)cycle completedTask:(NSInteger)completedCount ofTotalTask:(NSInteger)count withTotalTime:(NSTimeInterval)time
{
    NSString *viewColorString;
    NSString *cycleTitle;
    
    switch (cycle) {
        case TaskCycle:
            cycleTitle = @"Task Session";
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
    
    NSString *completedSessionCountString = [NSString stringWithFormat:@"%ld", (long) completedCount];
    NSString *targetSessioncountString = [NSString stringWithFormat:@"/%ld", (long) self.repeatCount];
    
    self.sessionCountLabel.attributedText = [self combineFormattedString:completedSessionCountString withString:targetSessioncountString];
    
    self.totalTaskTimeLabel.attributedText = [self stringifyTimeUsingAttributedString:(int)time];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.mainView.backgroundColor = [UIColor colorWithString:viewColorString];
    }];
}

- (void)taskFinished:(ZGCountDownTimer *)sender totalTaskTime:(NSTimeInterval)time sessionCount:(NSInteger)count
{
    // Update UI.
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"TASK FINISHED");
        self.resetButton.hidden = YES;
        self.skipButton.hidden = NO;
        // Set start button title to 'START' after finishing timer.
        [self.startButton setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
    });
    
    // Show task summary up on completion of task.
    [self showTaskSummaryWithDuration:time sessionCount:count];
    
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
    NSDate *finishTime = [NSDate date];
    NSDate *finishDate = [self truncateTimeFromDate:finishTime];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Event"];
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"finishDate == %@", finishDate],
                                                                                                  [NSPredicate predicateWithFormat:@"task == %@", task]]];
    [request setPredicate:compoundPredicate];
    
    NSError *error = nil;
    NSArray *events = [self.managedObjectContext executeFetchRequest:request error:&error];

    if (events.count == 0) {
        NSLog(@"No event exists for this task");
        NSEntityDescription *eventEntity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
        
        //Initialize Event.
        Event *newEvent = [[Event alloc] initWithEntity:eventEntity insertIntoManagedObjectContext:self.managedObjectContext];
        
        //Populate Event details.
        newEvent.finishTime = finishTime;
        newEvent.finishDate = finishDate;
        newEvent.totalTaskTime = [NSNumber numberWithDouble:totalTime];
        newEvent.totalSessionCount = [NSNumber numberWithInteger:count];
        
        [task addEventsObject:newEvent];
    } else if (events.count == 1){
        NSLog(@"One Event exists");
        Event *event = [events lastObject];
        NSTimeInterval newTaskTime = [event.totalTaskTime integerValue] + totalTime;
        NSInteger newSessionCount = [event.totalSessionCount integerValue] + count;
        
        event.finishTime = finishTime;
        event.totalTaskTime = [NSNumber numberWithDouble:newTaskTime];
        event.totalSessionCount = [NSNumber numberWithInteger:newSessionCount];
        
        [task addEventsObject:event];
    } else {
        NSLog(@"There are more evntes for task on same day. Something wrong!!!!");
    }
    
    [self saveContext];
}

- (NSDate *)truncateTimeFromDate:(NSDate *)fromDate;
{
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSCalendarUnit unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
    NSDateComponents *fromDateComponents = [calendar components:unitFlags fromDate:fromDate ];
    return [calendar dateFromComponents:fromDateComponents];
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
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:26.0f],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Add a new task to start using Listie.";
    
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
    
    return [[NSAttributedString alloc] initWithString:@"Add a task" attributes:attributes];
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
    [self addNewTask];
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
    return 72.0;
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
    int totalTaskTime = [task.taskTime intValue] * [task.repeatCount intValue];
    cell.totalTimeLabel.text = [self stringForTaskCellWithTime:totalTaskTime usingLongFormat:YES];
    
//    cell.reminderDateLabel.text = (indexPath.row % 3 == 0) ? @"26 May 2015 6:00 pm" : nil;
    
/*  reminder label.
 cell.reminderDateLabel.text = [self.formatter stringFromDate:task.reminderDate];
 */
    cell.taskColorView.backgroundColor = [UIColor colorWithString:task.taskColorString];
    
    if (![task.isSelected boolValue]) {
        cell.checkMarkButton.hidden = YES;
    } else {
        cell.checkMarkButton.hidden = NO;
    }
    
    //configure left buttons
    cell.leftButtons = @[[MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"EditCell.png"] backgroundColor:[UIColor colorWithString:@"#E67E22"] padding:25]];
    cell.leftSwipeSettings.transition = MGSwipeTransitionDrag;
    cell.leftExpansion.buttonIndex = 0;
    
    //configure right buttons
    cell.rightButtons = @[[MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"TrashCell.png"] backgroundColor:[UIColor colorWithString:@"#FF5733"] padding:25]];
    cell.rightSwipeSettings.transition = MGSwipeTransitionDrag;
    cell.rightExpansion.buttonIndex = 0;
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
        
        // flag set to mark task is selected.
        self.taskSelected = YES;
        
        // Change and save new task details.
        [self changeTaskDetails:newTask];
        
        // Store selected task info.
        [self saveContext];
        
        [self.repeatTimer resetTimer]; // Stops previous task without saving the event details.
        [self setUpRepeatTimer];
        [self setUpTimerViewInterfaceWith:self.isFullView];
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
            [self initializeTaskTimer];
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
            
            [self initializeTaskTimer];
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

- (void)initializeTaskTimer
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
    
    // Changes the view color to 'Alizarin' when a task is deleted.
    self.taskColorString = @"E74C3C";
    
    // Flag set to mark no task is selected.
    self.taskSelected = NO;
    
    [self setUpRepeatTimer];
    
    [self setUpTimerViewInterfaceWith:self.isFullView];
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

#pragma mark - FLEditTaskController delegate.

- (void)taskController:(FLEditTaskController *)controller didChangeTask:(Task *)task withTimerValue:(BOOL)changed
{
    NSLog(@"task delegate called");
    
    [self changeTaskDetails:task];
    
    if (!changed) {
        // Timer values not changed. Resets only task name and view color.
        
        self.titleLabel.text = self.taskName;
        
        NSString *viewColorString;
        CountDownCycleType cycle = self.repeatTimer.cycleType;
        
        switch (cycle) {
            case TaskCycle:
                viewColorString = self.taskColorString;
                break;
            case ShortBreakCycle:
                viewColorString = self.shortBreakColorString;
                break;
            case LongBreakCycle:
                viewColorString = self.longBreakColorString;
                break;
            default:
                break;
        }
        
        self.mainView.backgroundColor = [UIColor colorWithString:viewColorString];
        
    } else {
        NSLog(@"Timer values changed");
        
        if (self.repeatTimer.isRunning) {
            [self cancelTimerNotifications];
        }
        [self.repeatTimer resetTimer];
        [self setUpRepeatTimer];
        [self setUpTimerViewInterfaceWith:self.isFullView];
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

# pragma mark - CNPPopupController methods.

- (void)showTaskSummaryWithDuration:(NSTimeInterval)duration sessionCount:(NSInteger)count {
    
    NSString *completedSessionCountString = [NSString stringWithFormat:@"%ld", (long) count];
    NSString *targetSessioncountString = [NSString stringWithFormat:@"/%ld", (long) self.repeatCount];
    
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSAttributedString *durationTitle = [[NSAttributedString alloc] initWithString:@"Workout time" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18 weight:UIFontWeightRegular],
                                                                                                                NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName : paragraphStyle}];
    
    NSAttributedString *sessionTitle = [[NSAttributedString alloc] initWithString:@"Sessions completed" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18 weight:UIFontWeightRegular],
                                                                                                                     NSForegroundColorAttributeName : [UIColor whiteColor],
                                                                                                                     NSParagraphStyleAttributeName : paragraphStyle}];
    
    NSAttributedString *taskDurationString = [[NSAttributedString alloc] initWithAttributedString:[self timeStringForSummaryView:(int)duration]];
    
    NSAttributedString *sessionCountString = [[NSAttributedString alloc] initWithAttributedString:[self sessionStringForSummaryView:completedSessionCountString withString:targetSessioncountString]];
    
    CNPPopupButton *dismissButton = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
    [dismissButton setTitleColor:[UIColor colorWithRed:(44.0/255.0) green:(62.0/255.0) blue:(80.0/255.0) alpha:1.0] forState:UIControlStateNormal];
    dismissButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
    [dismissButton setTitle:@"Dissmiss" forState:UIControlStateNormal];
    dismissButton.backgroundColor = [UIColor clearColor];
    dismissButton.selectionHandler = ^(CNPPopupButton *button){
        [self.popupController dismissPopupControllerAnimated:YES];
    };
    
    UILabel *durationTitleLabel = [[UILabel alloc] init];
    durationTitleLabel.numberOfLines = 0;
    durationTitleLabel.attributedText = durationTitle;
    
    UILabel *taskDurationLabel = [[UILabel alloc] init];
    taskDurationLabel.numberOfLines = 0;
    taskDurationLabel.attributedText = taskDurationString;
    
    UILabel *sessionTitleLabel = [[UILabel alloc] init];
    sessionTitleLabel.numberOfLines = 0;
    sessionTitleLabel.attributedText = sessionTitle;
    
    UILabel *sessionCountLabel = [[UILabel alloc] init];
    sessionCountLabel.numberOfLines = 0;
    sessionCountLabel.attributedText = sessionCountString;
    
    self.popupController = [[CNPPopupController alloc] initWithContents:@[durationTitleLabel, taskDurationLabel, sessionTitleLabel, sessionCountLabel, dismissButton]];
    self.popupController.theme = [CNPPopupTheme defaultTheme];
    self.popupController.theme.popupStyle = CNPPopupStyleCentered;
    self.popupController.theme.presentationStyle = CNPPopupPresentationStyleSlideInFromTop;
    self.popupController.theme.cornerRadius = 15;
    self.popupController.theme.maxPopupWidth = 280;
    self.popupController.theme.backgroundColor = [UIColor colorWithRed:(52.0/255.0) green:(152.0/255.0) blue:(219.0/255.0) alpha:1.0];
    self.popupController.delegate = self;
    [self.popupController presentPopupControllerAnimated:YES];
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

- (NSString *)stringForTaskCellWithTime:(int)seconds usingLongFormat:(BOOL)longFormat
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
            if (minutes > 0) {
                return [NSString stringWithFormat:@"%ih %im", hours, minutes];
            } else {
                return [NSString stringWithFormat:@"%ih", hours];
            }
        } else {
            return [NSString stringWithFormat:@"%im", minutes];
        }
    }
}

- (NSMutableAttributedString *)combineFormattedString:(NSString *)firstString withString:(NSString *)secondString
{
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *firstStringAttributes = @{
                                            NSFontAttributeName:[UIFont systemFontOfSize:36 weight:UIFontWeightThin],
                                            NSForegroundColorAttributeName:[UIColor whiteColor],
                                            NSParagraphStyleAttributeName : paragraphStyle
                                            };
    NSDictionary *secondStringAttributes = @{
                                             NSFontAttributeName:[UIFont systemFontOfSize:16 weight:UIFontWeightLight],
                                             NSForegroundColorAttributeName:[UIColor whiteColor],
                                             NSParagraphStyleAttributeName : paragraphStyle
                                             };
    NSString *combinedString = [NSString stringWithFormat:@"%@%@", firstString, secondString];
    NSMutableAttributedString *modifiedString = [[NSMutableAttributedString alloc] initWithString:combinedString];
    [modifiedString setAttributes:firstStringAttributes range:[combinedString rangeOfString:firstString]];
    [modifiedString setAttributes:secondStringAttributes range:[combinedString rangeOfString:secondString]];
    
    return modifiedString;
}

- (NSMutableAttributedString *)stringifyTimeUsingAttributedString:(int)seconds
{
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;

    NSDictionary *timeAttributes = @{
                                     NSFontAttributeName:[UIFont systemFontOfSize:36 weight:UIFontWeightThin],
                                     NSForegroundColorAttributeName:[UIColor whiteColor],
                                     NSParagraphStyleAttributeName : paragraphStyle
                                     };
    NSDictionary *subAttributes = @{
                                    NSFontAttributeName:[UIFont systemFontOfSize:16 weight:UIFontWeightLight],
                                    NSForegroundColorAttributeName:[UIColor whiteColor],
                                    NSParagraphStyleAttributeName : paragraphStyle
                                    };

    int remainingSeconds = seconds;
    
    int hours = remainingSeconds / 3600;
    
    remainingSeconds = remainingSeconds - hours * 3600;
    
    int minutes = remainingSeconds / 60;
    
    remainingSeconds = remainingSeconds - minutes * 60;
    
    NSString *minuteString = @"m";
    NSString *hourString = @"h";
    
    if (hours > 0) {
        if (minutes > 0) {
            NSString *timeString = [NSString stringWithFormat:@"%i%@ %i%@", hours, hourString, minutes, minuteString];
            NSMutableAttributedString *modifiedString = [[NSMutableAttributedString alloc] initWithString:timeString attributes:timeAttributes];
            [modifiedString setAttributes:subAttributes range:[timeString rangeOfString:minuteString]];
            [modifiedString setAttributes:subAttributes range:[timeString rangeOfString:hourString]];
            return modifiedString;
        } else {
            NSString *timeString = [NSString stringWithFormat:@"%i%@", hours, hourString];
            NSMutableAttributedString *modifiedString = [[NSMutableAttributedString alloc] initWithString:timeString attributes:timeAttributes];
            [modifiedString setAttributes:subAttributes range:[timeString rangeOfString:hourString]];
            return modifiedString;
        }
    } else {
        NSString *timeString = [NSString stringWithFormat:@"%i%@", minutes, minuteString];
        NSMutableAttributedString *modifiedString = [[NSMutableAttributedString alloc] initWithString:timeString attributes:timeAttributes];
        [modifiedString setAttributes:subAttributes range:[timeString rangeOfString:minuteString]];
        return modifiedString;
    }
}

- (NSMutableAttributedString *)sessionStringForSummaryView:(NSString *)firstString withString:(NSString *)secondString
{
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *firstStringAttributes = @{
                                            NSFontAttributeName:[UIFont systemFontOfSize:40 weight:UIFontWeightLight],
                                            NSForegroundColorAttributeName:[UIColor whiteColor],
                                            NSParagraphStyleAttributeName : paragraphStyle
                                            };
    NSDictionary *secondStringAttributes = @{
                                             NSFontAttributeName:[UIFont systemFontOfSize:20 weight:UIFontWeightLight],
                                             NSForegroundColorAttributeName:[UIColor whiteColor],
                                             NSParagraphStyleAttributeName : paragraphStyle
                                             };
    NSString *combinedString = [NSString stringWithFormat:@"%@%@", firstString, secondString];
    NSMutableAttributedString *modifiedString = [[NSMutableAttributedString alloc] initWithString:combinedString];
    [modifiedString setAttributes:firstStringAttributes range:[combinedString rangeOfString:firstString]];
    [modifiedString setAttributes:secondStringAttributes range:[combinedString rangeOfString:secondString]];
    
    return modifiedString;
}

- (NSMutableAttributedString *)timeStringForSummaryView:(int)seconds
{
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *timeAttributes = @{
                                     NSFontAttributeName:[UIFont systemFontOfSize:40 weight:UIFontWeightLight],
                                     NSForegroundColorAttributeName:[UIColor whiteColor],
                                     NSParagraphStyleAttributeName : paragraphStyle
                                     };
    NSDictionary *subAttributes = @{
                                    NSFontAttributeName:[UIFont systemFontOfSize:20 weight:UIFontWeightLight],
                                    NSForegroundColorAttributeName:[UIColor whiteColor],
                                    NSParagraphStyleAttributeName : paragraphStyle
                                    };
    
    int remainingSeconds = seconds;
    
    int hours = remainingSeconds / 3600;
    
    remainingSeconds = remainingSeconds - hours * 3600;
    
    int minutes = remainingSeconds / 60;
    
    remainingSeconds = remainingSeconds - minutes * 60;
    
    NSString *minuteString = @"min";
    NSString *hourString = @"hr";
    
    if (hours > 0) {
        if (minutes > 0) {
            NSString *timeString = [NSString stringWithFormat:@"%i%@ %i%@", hours, hourString, minutes, minuteString];
            NSMutableAttributedString *modifiedString = [[NSMutableAttributedString alloc] initWithString:timeString attributes:timeAttributes];
            [modifiedString setAttributes:subAttributes range:[timeString rangeOfString:minuteString]];
            [modifiedString setAttributes:subAttributes range:[timeString rangeOfString:hourString]];
            return modifiedString;
        } else {
            NSString *timeString = [NSString stringWithFormat:@"%i%@", hours, hourString];
            NSMutableAttributedString *modifiedString = [[NSMutableAttributedString alloc] initWithString:timeString attributes:timeAttributes];
            [modifiedString setAttributes:subAttributes range:[timeString rangeOfString:hourString]];
            return modifiedString;
        }
    } else {
        NSString *timeString = [NSString stringWithFormat:@"%i%@", minutes, minuteString];
        NSMutableAttributedString *modifiedString = [[NSMutableAttributedString alloc] initWithString:timeString attributes:timeAttributes];
        [modifiedString setAttributes:subAttributes range:[timeString rangeOfString:minuteString]];
        return modifiedString;
    }
}

@end
