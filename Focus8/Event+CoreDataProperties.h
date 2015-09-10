//
//  Event+CoreDataProperties.h
//  Focus8
//
//  Created by Sibin Baby on 10/09/2015.
//  Copyright © 2015 FocusApps. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Event.h"

NS_ASSUME_NONNULL_BEGIN

@interface Event (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *finishDate;
@property (nullable, nonatomic, retain) NSNumber *totalTaskTime;
@property (nullable, nonatomic, retain) Task *task;

@end

NS_ASSUME_NONNULL_END
