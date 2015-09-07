//
//  FLColorPicker.m
//  Focus8
//
//  Created by Sibin Baby on 18/05/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import "FLColorPicker.h"
#import "UIColor+FlatColors.h"
#import "ColorUtils.h"
#import "FLColorCell.h"
#import "Focus8-Swift.h"

@interface FLColorPicker ()
@property (nonatomic, strong) NSArray *colors;

@end

@implementation FLColorPicker
{
    NSUInteger selectedColorIndex;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
//    self.colors = @[
//                    [UIColor flatTurquoiseColor],
//                    [UIColor flatGreenSeaColor],
//                    [UIColor flatEmeraldColor],
//                    [UIColor flatNephritisColor],
//                    [UIColor flatPeterRiverColor],
//                    [UIColor flatBelizeHoleColor],
//                    [UIColor flatAmethystColor],
//                    [UIColor flatWisteriaColor],
//                    [UIColor flatSunFlowerColor],
//                    [UIColor flatOrangeColor],
//                    [UIColor flatCarrotColor],
//                    [UIColor flatPumpkinColor],
//                    [UIColor flatAlizarinColor],
//                    [UIColor flatPomegranateColor],
//                    [UIColor flatWetAsphaltColor],
//                    [UIColor flatMidnightBlueColor]
//                    ];
    
    self.colors = @[@"1ABC9C",
                    @"Belize",
                    @"8E44AD",
                    @"E74C3C",
                    @"E67E22",
                    @"2C3E50",
                    @"cyan",
                    @"purple"
                    ];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    selectedColorIndex = [self.colors indexOfObject:self.selectedColor];
}

#pragma mark - TableView datasource methods.

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.colors count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ColorCell";
    FLColorCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.contentView.backgroundColor = [UIColor colorWithString:self.colors[indexPath.row]];
    
    if (indexPath.row == selectedColorIndex) {
        cell.checkmarkButton.hidden = NO;
    } else
    {
        cell.checkmarkButton.hidden = YES;
    }
    
    return cell;
}

#pragma mark - TableView Delegate methods.

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (selectedColorIndex != NSNotFound) {
        FLColorCell *cell = (FLColorCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedColorIndex inSection:0]];
        cell.checkmarkButton.hidden = YES;
    }
    
    selectedColorIndex = indexPath.row;
    FLColorCell *cell = (FLColorCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.checkmarkButton.animation = @"zoomIn";
    cell.checkmarkButton.duration = 0.5;
    cell.checkmarkButton.hidden = NO;
    [cell.checkmarkButton animate];
    
    [self.delegate colorPicker:self didSelectColor:self.colors[indexPath.row] forCycle:self.selectedPicker];
}

@end
