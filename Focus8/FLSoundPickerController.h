//
//  FLSoundPickerController.h
//  Focus8
//
//  Created by Sibin Baby on 28/08/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLSoundPickerController;

@protocol FLSoundPickerControllerDelegate <NSObject>

- (void)soundPickerController:(FLSoundPickerController *)controller didSelectSound:(NSString *)sound;

@end

@interface FLSoundPickerController : UITableViewController

@property (nonatomic, weak) id <FLSoundPickerControllerDelegate> delegate;
@property (nonatomic, strong) NSString *selectedSound;

@end
