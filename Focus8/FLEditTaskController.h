//
//  FLEditTaskController.h
//  Focus8
//
//  Created by Sibin Baby on 17/03/2015.
//  Copyright (c) 2014 FocusApps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLEditTaskController;
@class Task;

@protocol FLTaskControllerDelegate <NSObject>

- (void)taskController:(FLEditTaskController *)controller didChangeTask:(Task *)task withTimerValue:(BOOL)changed;

@end

@interface FLEditTaskController : UITableViewController

@property (nonatomic, weak) id <FLTaskControllerDelegate> delegate;
@property (nonatomic, strong) Task *task;
@property (nonatomic, assign, getter = isTaskEditing) BOOL taskEditing;

- (IBAction)cancel:(UIBarButtonItem *)sender;
- (IBAction)save:(UIBarButtonItem *)sender;

@end
