//
//  Task.h
//  Focus8
//
//  Created by Sibin Baby on 7/09/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Event;

@interface Task : NSManagedObject

@property (nonatomic, retain) NSNumber * isSelected;
@property (nonatomic, retain) NSString * longBreakColor;
@property (nonatomic, retain) NSNumber * longBreakDelay;
@property (nonatomic, retain) NSNumber * longBreakTime;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * reminderDate;
@property (nonatomic, retain) NSNumber * repeatCount;
@property (nonatomic, retain) NSString * shortBreakColor;
@property (nonatomic, retain) NSNumber * shortBreakTime;
@property (nonatomic, retain) NSString * taskColor;
@property (nonatomic, retain) NSNumber * taskTime;
@property (nonatomic, retain) NSString * uniqueID;
@property (nonatomic, retain) NSSet *events;
@end

@interface Task (CoreDataGeneratedAccessors)

- (void)addEventsObject:(Event *)value;
- (void)removeEventsObject:(Event *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;

@end
