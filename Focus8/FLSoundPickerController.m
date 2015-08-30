//
//  FLSoundPickerController.m
//  Focus8
//
//  Created by Sibin Baby on 28/08/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import "FLSoundPickerController.h"
#import <AVFoundation/AVFoundation.h>

@interface FLSoundPickerController ()
@property (nonatomic, strong) NSArray *soundArray;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@end

@implementation FLSoundPickerController
{
    NSUInteger selectedIndex;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Plays sound even if the phone is in silent mode.
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                     withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                           error:nil];

    // Hide back button on Navigation bar.
    //self.navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(exitSoundPicker)];
    barButtonItem.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = barButtonItem;
    
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
   
    self.selectedSound = self.soundArray[indexPath.row];
    
    // Play selected sound
    if (indexPath.row != 0) {
        [self playSound:self.soundArray[indexPath.row]];
    } else {
        // Stop sound when 'None' is selected.
        [self.audioPlayer stop];
    }
}

- (void)playSound:(NSString *)sound
{
    NSURL* url =[[NSBundle mainBundle] URLForResource:sound withExtension:@"wav"];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:NULL];
    
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer stop];
    }
        
    [self.audioPlayer play];
}

- (void)exitSoundPicker
{
    // Delegate method
    [self.delegate soundPickerController:self didSelectSound:self.selectedSound];
    
    [[self navigationController] popViewControllerAnimated:YES];
}

@end
