//
//  Event.h
//  Focus8
//
//  Created by Sibin Baby on 6/06/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Task;

@interface Event : NSManagedObject

@property (nonatomic, retain) NSDate * finishDate;
@property (nonatomic, retain) NSNumber * totalTaskTime;
@property (nonatomic, retain) Task *task;

@end
