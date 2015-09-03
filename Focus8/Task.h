//
//  Task.h
//  Focus8
//
//  Created by Sibin Baby on 3/09/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Event;

@interface Task : NSManagedObject

@property (nonatomic, retain) NSNumber * isSelected;
@property (nonatomic, retain) id longBreakColor;
@property (nonatomic, retain) NSNumber * longBreakDelay;
@property (nonatomic, retain) NSNumber * longBreakTime;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * reminderDate;
@property (nonatomic, retain) NSNumber * repeatCount;
@property (nonatomic, retain) id shortBreakColor;
@property (nonatomic, retain) NSNumber * shortBreakTime;
@property (nonatomic, retain) id taskColor;
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
