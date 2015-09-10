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
@property (nonatomic, strong) NSArray *colorNames;
@property (nonatomic, strong) NSArray *colorStrings;
@property (nonatomic, strong) NSDictionary *colors;

@end

@implementation FLColorPicker
{
    NSUInteger selectedColorIndex;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(exitColorPicker)];
    barButtonItem.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = barButtonItem;
    
    self.colorNames = @[@"Pomegranate",
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
    
    self.colorStrings = @[@"C0392B",
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
    
    self.colors = [NSDictionary dictionaryWithObjects:self.colorNames forKeys:self.colorStrings];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    selectedColorIndex = [self.colorStrings indexOfObject:self.selectedColorString];
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
    return [self.colorStrings count];
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
    cell.colorView.backgroundColor = [UIColor colorWithString:self.colorStrings[indexPath.row]];
    cell.colorLabel.text = [self.colors objectForKey:self.colorStrings[indexPath.row]];
    cell.colorLabel.textColor = [UIColor colorWithString:self.colorStrings[indexPath.row]];
    
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
    
    // Hide check mark on previous row if new color row selected.
    if (selectedColorIndex != NSNotFound) {
        FLColorCell *oldCell = (FLColorCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedColorIndex inSection:0]];
        oldCell.checkmarkButton.hidden = YES;
    }
    
    selectedColorIndex = indexPath.row;
    
    self.selectedColorString = self.colorStrings[indexPath.row];
    
    FLColorCell *cell = (FLColorCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.checkmarkButton.animation = @"zoomIn";
    cell.checkmarkButton.duration = 0.5;
    cell.checkmarkButton.hidden = NO;
    [cell.checkmarkButton animate];
}

- (void)exitColorPicker
{
    [self.delegate colorPicker:self didSelectColor:self.selectedColorString forPicker:self.selectedPicker];
    
    [[self navigationController] popViewControllerAnimated:YES];
}

@end
