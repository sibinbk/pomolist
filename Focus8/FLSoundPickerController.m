//
//  FLSoundPickerController.m
//  Focus8
//
//  Created by Sibin Baby on 28/08/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import "FLSoundPickerController.h"

@interface FLSoundPickerController ()
@property (nonatomic, strong) NSArray *soundArray;
@end

@implementation FLSoundPickerController
{
    NSUInteger selectedIndex;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.soundArray = @[@"None",
                        @"Caribbean",
                        @"Glissful",
                        @"Ready",
                        @"RingRing",
                        @"RobotRattle",
                        @"Woodpecker"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    selectedIndex = [self.soundArray indexOfObject:self.selectedSound];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.soundArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"SoundCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // Configure the cell...
    cell.textLabel.text = [NSString stringWithFormat:@"%@",self.soundArray[indexPath.row]];
    
    if (indexPath.row == selectedIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.textColor = [UIColor blueColor];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    return cell;
}

#pragma  mark - Table view delegate.

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (selectedIndex != NSNotFound) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0]];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    selectedIndex = indexPath.row;
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.textLabel.textColor = [UIColor blueColor];
    
    [self.delegate soundPickerController:self didSelectSound:self.soundArray[indexPath.row]];
}

@end
