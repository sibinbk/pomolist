//
//  FLSessionCountPickerController.h
//  Focus8
//
//  Created by Sibin Baby on 5/07/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLSessionCountPickerController;

@protocol FLSessionCountPickerDelegate <NSObject>

- (void)pickerController:(FLSessionCountPickerController *)controller didSelectTargetTaskSessions:(NSInteger)count;
@end

@interface FLSessionCountPickerController : UIViewController
@property (nonatomic, weak) id <FLSessionCountPickerDelegate> delegate;
@property (nonatomic) NSTimeInterval taskSessionTime;
@property (nonatomic) NSInteger taskSessionCount;
@end
