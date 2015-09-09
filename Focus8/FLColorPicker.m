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
@property (nonatomic, strong) NSArray *colorName;
@property (nonatomic, strong) NSArray *colorString;
@property (nonatomic, strong) NSDictionary *colors;

@end

@implementation FLColorPicker
{
    NSUInteger selectedColorIndex;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.colorName = @[@"Pomegranate",
                       @"Alizarin",
                       @"Pumpkin",
                       @"Carrot",
                       @"Green Sea",
                       @"Turquoise",
                       @"Nephritis",
                       @"Belize Hole",
                       @"Peter River",
                       @"Wisteria",
                       @"Deep Purple",
                       @"Midnight Blue"];
    
    self.colorString = @[@"C0392B",
                         @"E74C3C",
                         @"D35400",
                         @"E67E22",
                         @"16A085",
                         @"1ABC9C",
                         @"27AE60",
                         @"2980B9",
                         @"3498DB",
                         @"8E44AD",
                         @"673AB7",
                         @"2C3E50"];
    
    self.colors = [NSDictionary dictionaryWithObjects:self.colorName forKeys:self.colorString];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    selectedColorIndex = [self.colorString indexOfObject:self.selectedColor];
}

#pragma mark - TableView datasource methods.

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.colorString count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ColorCell";
    
    FLColorCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.contentView.backgroundColor = [UIColor whiteColor];
    cell.colorView.backgroundColor = [UIColor colorWithString:self.colorString[indexPath.row]];
    cell.colorLabel.text = [self.colors objectForKey:self.colorString[indexPath.row]];
    cell.colorLabel.textColor = [UIColor colorWithString:self.colorString[indexPath.row]];
    
    if (indexPath.row == selectedColorIndex) {
        cell.checkmarkButton.hidden = NO;
    } else {
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
    
    [self.delegate colorPicker:self didSelectColor:self.colorString[indexPath.row] forCycle:self.selectedPicker];
}

@end
