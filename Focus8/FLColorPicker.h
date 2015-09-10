//
//  FLColorPicker.h
//  Focus8
//
//  Created by Sibin Baby on 18/05/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLColorPicker;

@protocol FLColorPickerDelegate <NSObject>

- (void)colorPicker:(FLColorPicker *)controller didSelectColor:(NSString *)colorString forPicker:(NSString *)picker;

@end


@interface FLColorPicker : UITableViewController

@property (nonatomic, weak) id <FLColorPickerDelegate> delegate;
@property (nonatomic, strong) NSString *selectedColorString;
@property (nonatomic, strong) NSString *selectedPicker;
@end
