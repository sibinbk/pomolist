//
//  FLPickerController.h
//  Focus8
//
//  Created by Sibin Baby on 13/11/2014.
//  Copyright (c) 2014 FocusApps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLPickerController;

@protocol FLPickerControllerDelegate <NSObject>

- (void)pickerController:(FLPickerController *)controller didSelectValue:(NSString *)value forPicker:(NSString *)name;

@end

@interface FLPickerController : UITableViewController

@property (nonatomic, weak) id <FLPickerControllerDelegate> delegate;
@property (strong, nonatomic) NSArray *tableArray;
@property (strong, nonatomic) NSString *selectedValue;
@property (strong, nonatomic) NSString *selectedPicker;

@end
