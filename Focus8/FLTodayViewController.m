//
//  FLTodayViewController.m
//  Focus8
//
//  Created by Sibin Baby on 6/10/2015.
//  Copyright © 2015 FocusApps. All rights reserved.
//

#import "FLTodayViewController.h"
#import "AppDelegate.h"
#import "ColorUtils.h"
#import "NSAttributedString+CCLFormat.h"
#import "Focus8-Swift.h"
#import "Task.h"
#import "Event.h"

@interface FLTodayViewController () <NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *taskNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *percentageLabel;
@property (weak, nonatomic) IBOutlet UILabel *completedTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *completedSessionLabel;
@property (weak, nonatomic) IBOutlet DesignableView *todayView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@end

@implementation FLTodayViewController
@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Make navigation bar transparent and set custom font for title.
    [[self.navigationController navigationBar] setBackgroundImage:[UIImage new]
                                                    forBarMetrics:UIBarMetricsDefault];
    [self.navigationController navigationBar].shadowImage = [UIImage new];
    [self.navigationController navigationBar].translucent = NO;
    
    [self.navigationController.navigationBar setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                                      [UIColor whiteColor], NSForegroundColorAttributeName,
                                                                      [UIFont fontWithName:@"AvenirNext-Regular" size:22.0], NSFontAttributeName, nil]];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    [self getTodayViewForTask:self.task];
}

// Return AppDelegate's ManagedObjectContext.
-(NSManagedObjectContext *)managedObjectContext
{
    return [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
}

- (IBAction)dismissView:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)getTodayViewForTask:(Task *)task
{
    NSDate *today = [self truncateTimeFromDate:[NSDate date]];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Event"];
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"finishDate == %@", today],
                                                                                                  [NSPredicate predicateWithFormat:@"task == %@", task]]];
    [request setPredicate:compoundPredicate];
    
    NSError *error = nil;
    NSArray *events = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    Event *event = [events lastObject];
    
    NSAttributedString *completedTimeString = [self timeStringFromCompletedDuration:(int)[event.totalTaskTime integerValue]];
    NSAttributedString *plannedTimeString = [self timeStringFromTargetDuration:(int)([task.taskTime integerValue] * [task.repeatCount integerValue])];
    
    NSString *completedSessionCountString = [NSString stringWithFormat:@"%ld", (long) [event.totalSessionCount integerValue]];
    NSString *targetSessioncountString = [NSString stringWithFormat:@" %ld", (long) [task.repeatCount integerValue]];
    /* 'Space' before targetSessionCount string is a must. Otherwise the rage of string calculation could be wrong when both target and completed session counts are same. */
    
    self.dateLabel.text = [self dateStringForDate:today];
    self.taskNameLabel.text = task.name;
    self.percentageLabel.attributedText = [self formattedTaskPercentageString:[self percentageOfTaskCompleted:event]];
    
    self.completedTimeLabel.attributedText = [NSAttributedString attributedStringWithFormat:@"%@\n%@", completedTimeString, plannedTimeString];
    self.completedSessionLabel.attributedText = [self formattedSessionString:completedSessionCountString withString:targetSessioncountString];
}

- (NSDate *)truncateTimeFromDate:(NSDate *)fromDate;
{
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSCalendarUnit unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
    NSDateComponents *fromDateComponents = [calendar components:unitFlags fromDate:fromDate ];
    return [calendar dateFromComponents:fromDateComponents];
}

- (NSString *)dateStringForDate:(NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    NSString *dateString = [formatter stringFromDate:date];
    
    return dateString;
}
- (double)percentageOfTaskCompleted:(Event *)event
{
    if (!event) {
        // No event record available.
        return 0;
    }
    
    Task *task = event.task;
    
    double actualTaskDuration = [task.taskTime integerValue] * [task.repeatCount integerValue];
    double completedTaskDuration = [event.totalTaskTime integerValue];
    
    double percentageCompleted = round((completedTaskDuration / actualTaskDuration) * 100);
    
    return percentageCompleted;
}

#pragma mark - String formatting methods.

- (NSMutableAttributedString *)formattedSessionString:(NSString *)firstString withString:(NSString *)secondString
{
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentRight;
    
    NSDictionary *firstStringAttributes = @{
                                            NSFontAttributeName:[UIFont systemFontOfSize:30 weight:UIFontWeightLight],
                                            NSForegroundColorAttributeName:[UIColor whiteColor],
                                            NSParagraphStyleAttributeName : paragraphStyle
                                            };
    NSDictionary *secondStringAttributes = @{
                                             NSFontAttributeName:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular],
                                             NSForegroundColorAttributeName:[UIColor darkGrayColor],
                                             NSParagraphStyleAttributeName : paragraphStyle
                                             };
    
    NSString *combinedString = [NSString stringWithFormat:@"%@\n%@", firstString, secondString];
    NSMutableAttributedString *modifiedString = [[NSMutableAttributedString alloc] initWithString:combinedString];
    [modifiedString setAttributes:firstStringAttributes range:[combinedString rangeOfString:firstString]];
    [modifiedString setAttributes:secondStringAttributes range:[combinedString rangeOfString:secondString]];
    
    return modifiedString;
}

- (NSMutableAttributedString *)timeStringFromCompletedDuration:(int)seconds
{
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentRight;
    
    NSDictionary *timeAttributes = @{
                                     NSFontAttributeName:[UIFont systemFontOfSize:30 weight:UIFontWeightLight],
                                     NSForegroundColorAttributeName:[UIColor whiteColor],
                                     NSParagraphStyleAttributeName:paragraphStyle
                                     };
    NSDictionary *subAttributes = @{
                                    NSFontAttributeName:[UIFont systemFontOfSize:30 weight:UIFontWeightLight],
                                    NSForegroundColorAttributeName:[UIColor whiteColor],
                                    NSParagraphStyleAttributeName:paragraphStyle
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

- (NSMutableAttributedString *)timeStringFromTargetDuration:(int)seconds
{
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentRight;
    
    NSDictionary *timeAttributes = @{
                                     NSFontAttributeName:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular],
                                     NSForegroundColorAttributeName:[UIColor darkGrayColor],
                                     NSParagraphStyleAttributeName:paragraphStyle
                                     };
    NSDictionary *subAttributes = @{
                                    NSFontAttributeName:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular],
                                    NSForegroundColorAttributeName:[UIColor darkGrayColor],
                                    NSParagraphStyleAttributeName:paragraphStyle
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

- (NSMutableAttributedString *)formattedTaskPercentageString:(double)percentage
{
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *percentageAttributes = @{
                                           NSFontAttributeName:[UIFont systemFontOfSize:70 weight:UIFontWeightThin],
                                           NSForegroundColorAttributeName:[UIColor whiteColor],
                                           NSParagraphStyleAttributeName:paragraphStyle
                                           };
    NSDictionary *symbolAttributes = @{
                                       NSFontAttributeName:[UIFont systemFontOfSize:20 weight:UIFontWeightLight],
                                       NSForegroundColorAttributeName:[UIColor whiteColor],
                                       NSParagraphStyleAttributeName:paragraphStyle
                                       };
    
    NSString *symbolString = @"%";
    NSString *percentageString = [NSString stringWithFormat:@"%0.f%@", percentage, symbolString];
    
    NSMutableAttributedString *modifiedString = [[NSMutableAttributedString alloc] initWithString:percentageString attributes:percentageAttributes];
    [modifiedString setAttributes:symbolAttributes range:[percentageString rangeOfString:symbolString]];
    return modifiedString;
}

@end
