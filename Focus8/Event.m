//
//  Event.m
//  Focus8
//
//  Created by Sibin Baby on 10/09/2015.
//  Copyright © 2015 FocusApps. All rights reserved.
//

#import "Event.h"
#import "Task.h"

@implementation Event

// Insert code here to add functionality to your managed object subclass

@dynamic dateSection;

- (NSString *)dateSection {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateStyle = NSDateFormatterFullStyle;
    NSString *sectionTitle = [formatter stringFromDate:self.finishTime];
    
    return sectionTitle;
}

@end
