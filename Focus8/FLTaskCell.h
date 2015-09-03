//
//  FLTaskCell.h
//  Focus8
//
//  Created by Sibin Baby on 21/05/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"
#import "Focus8-Swift.h"

@interface FLTaskCell : MGSwipeTableCell
@property (weak, nonatomic) IBOutlet UILabel *taskNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *cycleCountLabel;
//@property (weak, nonatomic) IBOutlet UILabel *reminderDateLabel;
@property (weak, nonatomic) IBOutlet DesignableView *taskColorView;
@property (weak, nonatomic) IBOutlet UILabel *taskTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;

@end
