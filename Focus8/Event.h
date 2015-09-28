//
//  Event.h
//  Focus8
//
//  Created by Sibin Baby on 10/09/2015.
//  Copyright © 2015 FocusApps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Task;

NS_ASSUME_NONNULL_BEGIN

@interface Event : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

@property (nullable, nonatomic, retain) NSString *dateSection;

@end

NS_ASSUME_NONNULL_END

#import "Event+CoreDataProperties.h"
