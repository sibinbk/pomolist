//
//  ZGCountDownTimer.h
//  ZGCountDownTimer
//
//  Created by Kyle Fang on 2/28/13.
//  Copyright (c) 2013 Kyle Fang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CountDownCycleType) {
    TaskCycle,
    ShortBreakCycle,
    LongBreakCycle
};

@class ZGCountDownTimer;

@protocol ZGCountDownTimerDelegate <NSObject>

@optional

/** Timer's delegates
 
 @param sender      the timer that is sender delegate.
 @param timePassed  the time has passed in seconds.
 @param totalTime  total time in seconds.
 */

- (void)secondUpdated:(ZGCountDownTimer *)sender countDownTimePassed:(NSTimeInterval)timePassed ofTotalTime:(NSTimeInterval)totalTime;

- (void)minutesUpdated:(ZGCountDownTimer *)sender countDownTimePassed:(NSTimeInterval)timePassed ofTotalTime:(NSTimeInterval)totalTime;

- (void)hoursUpdated:(ZGCountDownTimer *)sender countDownTimePassed:(NSTimeInterval)timePassed ofTotalTime:(NSTimeInterval)totalTime;

- (void)countDownCompleted:(ZGCountDownTimer *)sender;

// delegate methods for task/break notifications.
- (void)taskSessionCompleted:(ZGCountDownTimer *)sender;

- (void)shortBreakCompleted:(ZGCountDownTimer *)sender;

- (void)longBreakCompleted:(ZGCountDownTimer *)sender;

// Delegate method for Cycle change notification and view colour change.
- (void)countDownCycleChanged:(ZGCountDownTimer *)sender cycle:(CountDownCycleType)newCycle withTaskCount:(NSInteger)count;

// Delegate method for Completed Task time.
- (void)taskTimeUpdated:(ZGCountDownTimer *)sender totalTime:(NSTimeInterval)time;

// Delegate method which return completed Task time.
- (void)taskFinished:(ZGCountDownTimer *)sender totalTaskTime:(NSTimeInterval)time;

@end

@interface ZGCountDownTimer : NSObject

/** get default timer.
 
 @return Default ZGCountDownTimer.
 */

+ (ZGCountDownTimer *)defaultCountDownTimer;

/** get timer for object.
 
 @param identifier timer's identifier, nil for default.
 @return ZGCountDownTimer object.
 */

+ (ZGCountDownTimer *)countDownTimerWithIdentifier:(NSString *)identifier;

/** timer's unique identifier */
@property (nonatomic, copy) NSString *timerIdentifier;

/** set up timer for the first time or restore it
 
 @param firstBLock              this block will be excuted if the time is been set up for the first time, you should set the count down time in this block.
 @param restoreFromBackup       this block will be excuted if the timer already exsit, if so, the #first# will not be excuted
 */

- (void)setupCountDownForTheFirstTime:(void (^)(ZGCountDownTimer *timer))firstBlock restoreFromBackUp:(void (^)(ZGCountDownTimer *timer))restoreFromBackup;

/** totalCountDownTime, should only set it in firstBlock */
@property (nonatomic) NSTimeInterval totalCountDownTime;

/** taskTime, should only set it in firstBlock */
@property (nonatomic) NSTimeInterval taskTime;

/** shortBreakTime, should only set it in firstBlock */
@property (nonatomic) NSTimeInterval shortBreakTime;

/** longBreakTime, should only set it in firstBlock */
@property (nonatomic) NSTimeInterval longBreakTime;

/** repeatCount, should only set it in firstBlock */
@property (nonatomic) NSInteger repeatCount;

/** longBreakDelay, should only set it in firstBlock */
@property (nonatomic) NSInteger longBreakDelay;

/** total time passed since the beginning of task. */
@property (nonatomic) NSTimeInterval timePassed;

/** total time required to finish upto current cycle */
@property (nonatomic) NSTimeInterval cycleFinishTime;

/** no. of completed task cycles. */
@property (nonatomic) NSInteger taskCount;

/** total no. of compled cycles. */
@property (nonatomic) NSInteger timerCycleCount;

/** Cycle type. */
@property (nonatomic) CountDownCycleType cycleType;

/** start timer
 @return success in starting timer, if timer completed or already started will return NO;
 */
- (BOOL)startCountDown;

/** pause timer
 
 @return success in pausing the timer, if timer is not running will return NO;
 */
- (BOOL)pauseCountDown;

/** stopCountDown calls resetTimer method and calls taskFinished delegate. **/
- (void)stopCountDown;

/** skip to next coundown cycle when the timer is paused **/
- (void)skipCountDown;

/** resets timer. the totalCountDownTime will not change   **/
- (void)resetTimer;

/** timer is running, it must be started */
@property (nonatomic, readonly) BOOL isRunning;

/** timer is started, it may not be running, it could be paused. */
@property (nonatomic, readonly) BOOL started;

/** ZGCountDownTimerDelegate */
@property (nonatomic, weak) id <ZGCountDownTimerDelegate> delegate;


/** help method
 
 @param timeInterval    remain countDownTime in secound.
 @param dateFormatter   custom dateFormatter.
 @return a string value to represent the countDownTime.
 */
+ (NSString *)getDateStringForTimeInterval:(NSTimeInterval )timeInterval;
+ (NSString *)getDateStringForTimeInterval:(NSTimeInterval )timeInterval withDateFormatter:(NSNumberFormatter *)dateFormatter;
@end
