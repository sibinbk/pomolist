//
//  ZGCountDownTimer.m
//  ZGCountDownTimer
//
//  Created by Kyle Fang on 2/28/13.
//  Copyright (c) 2013 Kyle Fang. All rights reserved.
//

#import "ZGCountDownTimer.h"

#define kZGTimePassed                       @"timePassed"
#define kZGTotalCountDownTime               @"totalCountDownTime"
#define kZGCompletedTaskTime                @"completedTaskTime"
#define kZGCompletedBreakTime               @"completedBreakTime"
#define kZGSkippedTaskTime                  @"skippedTaskTime"
#define kZGCountDownRunning                 @"countDownRunning"
#define kZGTaskTime                         @"taskTime"
#define kZGShortBreakTime                   @"shortBreakTime"
#define kZGLongBreakTime                    @"longBreakTime"
#define kZGCycleFinishTime                  @"cycleFinishTime"
#define kZGRepeatCount                      @"repeatCount"
#define kZGTaskCount                        @"taskCount"
#define kZGTimerCycleCount                  @"timerCycleCount"
#define kZGLongBreakDelay                   @"longBreakDelay"
#define kZGCountDownCycle                   @"countDownCycle"
#define kZGStartCountDate                   @"startCountDate"
#define kZGCycleChanged                     @"cycleChanged"
#define kZGCheckCycleChangeDelegate         @"checkCycleDelegate"

#define kZGCountDownUserDefaultKey          @"ZGCountDownUserDefaults"

@interface ZGCountDownTimer()

@property (nonatomic) NSTimer *defaultTimer;
@property (nonatomic) NSTimeInterval completedTaskTime;
@property (nonatomic) NSTimeInterval completedBreakTime;
@property (nonatomic) NSTimeInterval skippedTaskTime;
@property (nonatomic) NSDate *startCountDate;
@property (nonatomic) BOOL countDownRunning;
@property (nonatomic) BOOL cycleChanged;
@property (nonatomic) BOOL checkCycleChangeDelegate;

@end

@implementation ZGCountDownTimer

#pragma mark - init methods
static NSMutableDictionary *_countDownTimersWithIdentifier;

+ (ZGCountDownTimer *)defaultCountDownTimer
{
    return [self countDownTimerWithIdentifier:kZGCountDownUserDefaultKey];
}

+ (ZGCountDownTimer *)countDownTimerWithIdentifier:(NSString *)identifier
{
    if (!identifier) {
        identifier = kZGCountDownUserDefaultKey;
    }
    if (_countDownTimersWithIdentifier) {
        _countDownTimersWithIdentifier = [[NSMutableDictionary alloc] init];
    }
    ZGCountDownTimer *timer = [_countDownTimersWithIdentifier objectForKey:identifier];
    if (!timer) {
        timer = [[self alloc] init];
        timer.timerIdentifier = identifier;
        [_countDownTimersWithIdentifier setObject:timer forKey:identifier];
    }
    return timer;
}

#pragma mark - setup methods.

- (void)setupCountDownForTheFirstTime:(void (^)(ZGCountDownTimer *))firstBlock
                    restoreFromBackUp:(void (^)(ZGCountDownTimer *))restoreFromBackup
{
    if ([self backupExist]) {
        [self restoreTimerInfo];
        if (restoreFromBackup) {
            restoreFromBackup(self);
        }
    } else {
        if (firstBlock) {
            firstBlock(self);
        }
    }
}

#pragma mark - setters.

- (void)setTotalCountDownTime:(NSTimeInterval)totalCountDownTime
{
    _totalCountDownTime = totalCountDownTime;
    
    // The below method is for setting initial cycle values and setting the textlabel values with initial taskTime when the app launches for the first time.
    [self setInitialCycleValues];
}

- (void)setCountDownRunning:(BOOL)countDownRunning
{
    _countDownRunning = countDownRunning;
    
    if (!self.defaultTimer && countDownRunning) {
        [self setupDefaultTimer];
    }
    
    // Checks if Timer is paused.
    if (!countDownRunning) {
        if (self.started) {
            [self notifyDelegateWithPassedTime:self.timePassed ofCycleFinishTime:self.cycleFinishTime];
        }
    }
}

#pragma mark - timer API methods.

- (BOOL)isRunning
{
    // Returns 'YES' if the timer is running.
    return self.countDownRunning;
}

- (BOOL)started
{
    // Returns 'YES' if the timer has started.
    return self.timePassed > 0;
}

- (BOOL)startCountDown
{
    if (!self.countDownRunning) {
        if (!self.started) {
            self.startCountDate = [NSDate date];
        } else {
            self.startCountDate = [[NSDate date] dateByAddingTimeInterval:-self.timePassed];
        }
        self.countDownRunning = YES;
        //If 'YES' updates cycle name by calling Cycle change delegate method.
        self.checkCycleChangeDelegate = YES;
        
        [self backUpTimerInfo];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)pauseCountDown
{
    if (self.countDownRunning) {
        _countDownRunning = NO;
        //If 'YES' updates cycle name by calling Cycle change delegate method.
        self.checkCycleChangeDelegate = YES;
        [self backUpTimerInfo];
        
        if (self.defaultTimer) {
            NSLog(@"Timer invalidated");
            [self.defaultTimer invalidate];
            self.defaultTimer = nil;
        }
        
        return YES;
    } else {
        return NO;
    }
}

- (void)stopCountDown
{
    if (self.started) {
        if ([self.delegate respondsToSelector:@selector(taskFinished:totalTaskTime:)]) {
            if (self.cycleType == TaskCycle) {
                [self.delegate taskFinished:self totalTaskTime:(self.timePassed - (self.completedBreakTime + self.skippedTaskTime))];
            } else {
                [self.delegate taskFinished:self totalTaskTime:(self.completedTaskTime - self.skippedTaskTime)];
            }
        }
    }

    [self resetTimer];
}

- (void)resetTimer
{
    [self setInitialCycleValues];
    _countDownRunning = NO;
    
    if ([self backupExist]) {
        [self removeTimerInfoBackup];
    }
    
    if (self.defaultTimer) {
        NSLog(@"Timer invalidated");
        [self.defaultTimer invalidate];
        self.defaultTimer = nil;
    }
}
- (void)skipCountDown
{
    // Get the skipped time interval of Task cycle.
    if (self.cycleType == TaskCycle) {
        NSTimeInterval tempSkippedTaskTime = self.cycleFinishTime - self.timePassed;
        self.skippedTaskTime += tempSkippedTaskTime;
    }
    
    self.timePassed = self.cycleFinishTime;
    
    [self skipToNextCycle];
    if (self.cycleFinishTime > self.totalCountDownTime) {
        if ([self.delegate respondsToSelector:@selector(taskFinished:totalTaskTime:)]) {
            [self.delegate taskFinished:self totalTaskTime:(self.completedTaskTime - self.skippedTaskTime)];
        }
        [self resetTimer];
    } else {
        [self backUpTimerInfo];
        [self notifyDelegateWithPassedTime:self.timePassed ofCycleFinishTime:self.cycleFinishTime];
    }
}

#pragma mark - timer update method.

- (void)timerUpdated:(NSTimer *)timer
{
    if (self.countDownRunning) {
        
        if (self.cycleChanged) {
            self.cycleChanged = NO;
            [self calculateChangedCycleFinishTime];
        }
        
        if (self.cycleFinishTime > self.totalCountDownTime) {
            if ([self.delegate respondsToSelector:@selector(taskFinished:totalTaskTime:)]) {
                [self.delegate taskFinished:self totalTaskTime:(self.completedTaskTime - self.skippedTaskTime)];
            }
            [self resetTimer];
//            if ([self.delegate respondsToSelector:@selector(countDownCompleted:)]) {
//                [self.delegate countDownCompleted:self];
//            }
        } else {
            NSTimeInterval newTimePassed = round([self calcuateTimePassed]);
            NSLog(@"New TimePassed : %f", newTimePassed);
            
            if (newTimePassed < self.cycleFinishTime) {
                [self notifyDelegateWithPassedTime:newTimePassed ofCycleFinishTime:self.cycleFinishTime];
            } else if (newTimePassed == self.cycleFinishTime) {
                [self notifyDelegateWithPassedTime:newTimePassed ofCycleFinishTime:self.cycleFinishTime];
                self.cycleChanged = YES;
            } else {
                if (newTimePassed >= self.totalCountDownTime){
                    // Condition becomes true if the Countdown time finishes when the App is either in background or quit.
//                    if ([self.delegate respondsToSelector:@selector(countDownCompleted:)]) {
//                        [self.delegate countDownCompleted:self];
//                    }
                    if ([self.delegate respondsToSelector:@selector(taskFinished:totalTaskTime:)]) {
                        [self.delegate taskFinished:self totalTaskTime:(self.taskTime * self.repeatCount - self.skippedTaskTime)];
                    }
                    [self resetTimer];
                    newTimePassed = 0; // Hack to avoid loop when the app becomes active and task is already finished.
                    
                } else {
                    while (self.cycleFinishTime < newTimePassed) {
                        // Check current countdown cycle and skip to next cycle.
                        [self skipToNextCycle];
                        NSLog(@"In the loop");
                    }
                    [self notifyDelegateWithPassedTime:newTimePassed ofCycleFinishTime:self.cycleFinishTime];
                }
            }
            self.timePassed = newTimePassed;
        }
    }
}

- (void)calculateChangedCycleFinishTime
{
    switch (self.cycleType) {
        case TaskCycle:
            self.timerCycleCount++;
            if (![self checkIfLongBreakCycle:self.taskCount]) {
                self.cycleType = ShortBreakCycle;
                self.cycleFinishTime += self.shortBreakTime;
            } else {
                self.cycleType = LongBreakCycle;
                self.cycleFinishTime += self.longBreakTime;
            }
            self.completedTaskTime += self.taskTime;
            if ([self.delegate respondsToSelector:@selector(taskCompleted:)])
                [self.delegate taskCompleted:self];
            break;
        case ShortBreakCycle:
            self.cycleType = TaskCycle;
            self.taskCount++;
            self.timerCycleCount++;
            self.cycleFinishTime += self.taskTime;
            self.completedBreakTime += self.shortBreakTime;
            if ([self.delegate respondsToSelector:@selector(shortBreakCompleted:)])
                [self.delegate shortBreakCompleted:self];
            break;
        case LongBreakCycle:
            self.cycleType = TaskCycle;
            self.taskCount++;
            self.timerCycleCount++;
            self.cycleFinishTime += self.taskTime;
            self.completedBreakTime += self.longBreakTime;
            if ([self.delegate respondsToSelector:@selector(longBreakCompleted:)])
                [self.delegate longBreakCompleted:self];
            break;
    }
    
    self.checkCycleChangeDelegate = YES;
}

- (void)skipToNextCycle
{
    switch (self.cycleType) {
        case TaskCycle:
            self.timerCycleCount++;
            if (![self checkIfLongBreakCycle:self.taskCount]) {
                self.cycleType = ShortBreakCycle;
                self.cycleFinishTime += self.shortBreakTime;
            } else {
                self.cycleType = LongBreakCycle;
                self.cycleFinishTime += self.longBreakTime;
            }
            self.completedTaskTime += self.taskTime;
            break;
        case ShortBreakCycle:
            self.cycleType = TaskCycle;
            self.taskCount++;
            self.timerCycleCount++;
            self.cycleFinishTime += self.taskTime;
            self.completedBreakTime += self.shortBreakTime;
            break;
        case LongBreakCycle:
            self.cycleType = TaskCycle;
            self.taskCount++;
            self.timerCycleCount++;
            self.cycleFinishTime += self.taskTime;
            self.completedBreakTime += self.longBreakTime;
            break;
    }
    self.checkCycleChangeDelegate = YES;
}

#pragma mark - helper methods

- (NSTimeInterval)calcuateTimePassed
{
    NSTimeInterval tempTimePassed = [[NSDate date] timeIntervalSinceDate:self.startCountDate];
    NSLog(@"TempTime passed: %f", tempTimePassed);
    NSLog(@"Old TimePassed : %f", self.timePassed);
    
    // Checks previous value to avoid skipping the count number.
    if ((tempTimePassed - self.timePassed) < 0.5) {
        return (tempTimePassed + 1.0);
    } else {
        return (tempTimePassed);
    }
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

- (void)setupDefaultTimer
{
    self.defaultTimer = [NSTimer timerWithTimeInterval:1.f target:self selector:@selector(timerUpdated:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.defaultTimer forMode:NSRunLoopCommonModes];
    [self.defaultTimer fire];
}

- (void)setInitialCycleValues
{
    self.startCountDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    self.timePassed = 0;
    self.cycleFinishTime = self.taskTime;
    self.completedTaskTime = 0;
    self.completedBreakTime = 0;
    self.skippedTaskTime = 0;
    self.cycleType = TaskCycle;
    self.checkCycleChangeDelegate = YES;
    self.cycleChanged = NO;
    self.taskCount = 1;
    self.timerCycleCount = 1;
    [self notifyDelegateWithPassedTime:0 ofCycleFinishTime:self.taskTime];
}

- (void)notifyDelegateWithPassedTime:(NSTimeInterval)timePassed ofCycleFinishTime:(NSTimeInterval)finishTime
{
    NSLog(@"Delegate called");
    // Delegate method to update current Timer value.
    if ([self.delegate respondsToSelector:@selector(secondUpdated:countDownTimePassed:ofTotalTime:)]) {
        [self.delegate secondUpdated:self countDownTimePassed:timePassed ofTotalTime:finishTime];
    }
    
    // Delegate method to update Total Task Time.
    if ([self.delegate respondsToSelector:@selector(taskTimeUpdated:totalTime:)]) {
        if (self.cycleType == TaskCycle) {
            [self.delegate taskTimeUpdated:self totalTime:(timePassed - (self.completedBreakTime + self.skippedTaskTime))];
        } else {
            [self.delegate taskTimeUpdated:self totalTime:(self.completedTaskTime - self.skippedTaskTime)];
        }
    }
    
    // Delegate method to update change in cycle.
    if (self.checkCycleChangeDelegate) {
        self.checkCycleChangeDelegate = NO;
        if ([self.delegate respondsToSelector:@selector(countDownCycleChanged:cycle:withTaskCount:)]) {
            [self.delegate countDownCycleChanged:self cycle:self.cycleType withTaskCount:self.taskCount];
        }
    }
}

#pragma mark - backup/restore methods

- (BOOL)backupExist
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *timerInfo = [defaults objectForKey:self.timerIdentifier];
    return timerInfo != nil;
}

- (void)backUpTimerInfo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self timerInfoForBackup] forKey:self.timerIdentifier];
    [defaults synchronize];
}

- (void)restoreTimerInfo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self restoreFromTimerInfoBackup:[defaults objectForKey:self.timerIdentifier]];
}

- (void)removeTimerInfoBackup
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:self.timerIdentifier];
    [defaults synchronize];
}

- (NSDictionary *)timerInfoForBackup
{
    return @{
             kZGStartCountDate: self.startCountDate,
             kZGTimePassed: [NSNumber numberWithDouble:self.timePassed],
             kZGTotalCountDownTime: [NSNumber numberWithDouble:self.totalCountDownTime],
             kZGCountDownRunning: [NSNumber numberWithBool:self.countDownRunning],
             kZGTaskTime: [NSNumber numberWithDouble:self.taskTime],
             kZGShortBreakTime: [NSNumber numberWithDouble:self.shortBreakTime],
             kZGLongBreakTime: [NSNumber numberWithDouble:self.longBreakTime],
             kZGCycleFinishTime: [NSNumber numberWithDouble:self.cycleFinishTime],
             kZGCompletedTaskTime: [NSNumber numberWithDouble:self.completedTaskTime],
             kZGCompletedBreakTime: [NSNumber numberWithDouble:self.completedBreakTime],
             kZGSkippedTaskTime: [NSNumber numberWithDouble:self.skippedTaskTime],
             kZGRepeatCount: [NSNumber numberWithInteger:self.repeatCount],
             kZGTaskCount: [NSNumber numberWithInteger:self.taskCount],
             kZGTimerCycleCount: [NSNumber numberWithInteger:self.timerCycleCount],
             kZGLongBreakDelay : [NSNumber numberWithInteger:self.longBreakDelay],
             kZGCountDownCycle: [NSNumber numberWithInt:self.cycleType],
             kZGCycleChanged: [NSNumber numberWithBool:self.cycleChanged],
             kZGCheckCycleChangeDelegate: [NSNumber numberWithBool:self.checkCycleChangeDelegate]
             };
}

- (void)restoreFromTimerInfoBackup:(NSDictionary *)timerInfo
{
    _totalCountDownTime = [[timerInfo valueForKey:kZGTotalCountDownTime] doubleValue];
    self.timePassed = [[timerInfo valueForKey:kZGTimePassed] doubleValue];
    self.startCountDate = [timerInfo valueForKey:kZGStartCountDate];
    self.taskTime = [[timerInfo valueForKey:kZGTaskTime] doubleValue];
    self.shortBreakTime = [[timerInfo valueForKey:kZGShortBreakTime] doubleValue];
    self.longBreakTime = [[timerInfo valueForKey:kZGLongBreakTime] doubleValue];
    self.cycleFinishTime = [[timerInfo valueForKey:kZGCycleFinishTime] doubleValue];
    self.completedTaskTime = [[timerInfo valueForKey:kZGCompletedTaskTime] doubleValue];
    self.completedBreakTime = [[timerInfo valueForKey:kZGCompletedBreakTime] doubleValue];
    self.skippedTaskTime = [[timerInfo valueForKey:kZGSkippedTaskTime] doubleValue];
    self.repeatCount = [[timerInfo valueForKey:kZGRepeatCount] integerValue];
    self.taskCount = [[timerInfo valueForKey:kZGTaskCount] integerValue];
    self.timerCycleCount = [[timerInfo valueForKey:kZGTimerCycleCount] integerValue];
    self.longBreakDelay = [[timerInfo valueForKey:kZGLongBreakDelay] integerValue];
    self.cycleType = [[timerInfo valueForKey:kZGCountDownCycle] intValue];
    self.cycleChanged = [[timerInfo valueForKey:kZGCycleChanged] boolValue];
    self.checkCycleChangeDelegate = [[timerInfo valueForKey:kZGCheckCycleChangeDelegate] boolValue];
    self.countDownRunning = [[timerInfo valueForKey:kZGCountDownRunning] boolValue];
}

- (void)dealloc
{
    [self.defaultTimer invalidate];
    self.defaultTimer = nil;
}

+ (NSString *)getDateStringForTimeInterval:(NSTimeInterval)timeInterval
{
    return [self getDateStringForTimeInterval:timeInterval withDateFormatter:nil];
}

+ (NSString *)getDateStringForTimeInterval:(NSTimeInterval )timeInterval withDateFormatter:(NSNumberFormatter *)formatter
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

@end
