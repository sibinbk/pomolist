//
//  Task+CoreDataProperties.h
//  Focus8
//
//  Created by Sibin Baby on 29/09/2015.
//  Copyright © 2015 FocusApps. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Task.h"

NS_ASSUME_NONNULL_BEGIN

@interface Task (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *isSelected;
@property (nullable, nonatomic, retain) NSString *longBreakColorString;
@property (nullable, nonatomic, retain) NSNumber *longBreakDelay;
@property (nullable, nonatomic, retain) NSNumber *longBreakTime;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSDate *reminderDate;
@property (nullable, nonatomic, retain) NSNumber *repeatCount;
@property (nullable, nonatomic, retain) NSString *shortBreakColorString;
@property (nullable, nonatomic, retain) NSNumber *shortBreakTime;
@property (nullable, nonatomic, retain) NSString *taskColorString;
@property (nullable, nonatomic, retain) NSNumber *taskTime;
@property (nullable, nonatomic, retain) NSString *uniqueID;
@property (nullable, nonatomic, retain) NSSet<Event *> *events;

@end

@interface Task (CoreDataGeneratedAccessors)

- (void)addEventsObject:(Event *)value;
- (void)removeEventsObject:(Event *)value;
- (void)addEvents:(NSSet<Event *> *)values;
- (void)removeEvents:(NSSet<Event *> *)values;

@end

NS_ASSUME_NONNULL_END
