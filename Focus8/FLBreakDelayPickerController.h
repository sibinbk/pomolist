//
//  FLBreakDelayPickerController.h
//  Focus8
//
//  Created by Sibin Baby on 4/07/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLBreakDelayPickerController;

@protocol FLBreakDelayPickerDelagate <NSObject>

- (void)pickerController:(FLBreakDelayPickerController *)controller didSelectDelay:(NSInteger)delay;

@end

@interface FLBreakDelayPickerController : UIViewController

@property (nonatomic, weak) id <FLBreakDelayPickerDelagate> delegate;
@property (nonatomic, assign) NSInteger selectedValue;

@end
