//
//  FLPopUpPickerController.m
//  Focus8
//
//  Created by Sibin Baby on 4/06/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import "FLPopUpPickerController.h"
#import "UIColor+FlatColors.h"
#import "Focus8-Swift.h"

typedef NS_ENUM(NSInteger, PopAnimationType) {
    PopZoom,
    PopBounceIn
};

@interface FLPopUpPickerController () <UIPickerViewDataSource, UIPickerViewDelegate>
@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) UIView *popUpView;
@property (strong, nonatomic) UIView *titleView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIPickerView *pickerView;
@property (nonatomic) NSTimeInterval bounce1Duration;
@property (nonatomic) NSTimeInterval bounce2Duration;

@property (nonatomic, strong) NSMutableArray *timeListArray;
@property (nonatomic, strong) NSMutableArray *longBreakDelayArray;

@property (nonatomic) PopAnimationType animationType;

@end

@implementation FLPopUpPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Do any additional setup after loading the view, typically from a nib.
    self.timeListArray = (NSMutableArray *)@[@"1 minute", @"2 minutes", @"3 minutes", @"4 minutes", @"5 minutes", @"6 minutes", @"7 minutes", @"8 minutes", @"9 minutes", @"10 minutes",
                                             @"11 minutes", @"12 minutes", @"13 minutes", @"14 minutes", @"15 minutes", @"16 minutes", @"17 minutes", @"18 minutes", @"19 minutes", @"20 minutes",
                                             @"21 minutes", @"22 minutes", @"23 minutes", @"24 minutes", @"25 minutes", @"26 minutes", @"27 minutes", @"28 minutes", @"29 minutes", @"30 minutes"];
    
    self.longBreakDelayArray = (NSMutableArray *)@[@"1 cycle", @"2 cycles", @"3 cycles", @"4 cycles", @"5 cycles", @"6 cycles", @"7 cycles", @"8 cycles", @"9 cycles", @"10 cycles", @"11 cycles", @"12 cycles", @"13 cycles", @"14 cycles", @"15 cycles"];

    
    //Set animation timing.
    self.bounce1Duration = 0.13;
    self.bounce2Duration = 2 * self.bounce1Duration;
    
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    self.view.alpha = 0.0;
    
    // Container view.
    self.containerView = [[UIView alloc] init];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.containerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.containerView];
    
    self.popUpView = [[UIView alloc] init];
    self.popUpView.translatesAutoresizingMaskIntoConstraints = NO;
    self.popUpView.backgroundColor = [UIColor whiteColor];
    self.popUpView.clipsToBounds = YES;
    self.popUpView.layer.cornerRadius = 10.0;
    [self.containerView addSubview:self.popUpView];
    
    // Coloured Topbar for title and date.
    self.titleView = [[UIView alloc] init];
    self.titleView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.popUpView addSubview:self.titleView];
    
    // Title Label for Picker
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.titleView addSubview:self.titleLabel];
    
    UIView* bottomView = [[UIView alloc] init];
    bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    bottomView.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:.5];
    [self.popUpView addSubview:bottomView];
    
    //Background view for date picker.
    UIView *pickerContainerView = [[UIView alloc] init];
    pickerContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    pickerContainerView.backgroundColor = [UIColor whiteColor];
    pickerContainerView.clipsToBounds = YES;
    [self.popUpView addSubview:pickerContainerView];
    
    // Date picker.
    self.pickerView = [[UIPickerView alloc] init];
    self.pickerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.pickerView.backgroundColor = [UIColor whiteColor];
    self.pickerView.showsSelectionIndicator = YES;
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    [pickerContainerView addSubview:self.pickerView];
    
    // Cancel button for picker.
    UIButton* removeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    removeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [removeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [removeButton setTitleColor:[[removeButton titleColorForState:UIControlStateNormal] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
    removeButton.titleLabel.font = [UIFont systemFontOfSize:20.0];
    [removeButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [removeButton addTarget:self action:@selector(cancelSelection:) forControlEvents:UIControlEventTouchUpInside];
    [self.popUpView addSubview:removeButton];
    
    // Save button for picker.
    UIButton* saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [saveButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [saveButton setTitleColor:[[removeButton titleColorForState:UIControlStateNormal] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
    saveButton.titleLabel.font = [UIFont systemFontOfSize:20.0];
    [saveButton setTitle:@"Save" forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(saveSelection:) forControlEvents:UIControlEventTouchUpInside];
    [self.popUpView addSubview:saveButton];
    
    // Padding views.
    UIView *spacer = [UIView new];
    spacer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.popUpView addSubview:spacer];
    
    NSDictionary* layoutViews = NSDictionaryOfVariableBindings(_containerView, _popUpView, _titleView, bottomView, pickerContainerView, _pickerView, removeButton, saveButton, _titleLabel, spacer);
    
    [pickerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_pickerView]|"
                                                                                options:NSLayoutFormatAlignAllCenterX
                                                                                metrics:nil
                                                                                  views:layoutViews]];
    [pickerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_pickerView]|"
                                                                                options:NSLayoutFormatAlignAllCenterY
                                                                                metrics:nil
                                                                                  views:layoutViews]];
    
    [self.titleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-16-[_titleLabel]-16-|"
                                                                           options:NSLayoutFormatAlignAllCenterX
                                                                           metrics:nil
                                                                             views:layoutViews]];
    [self.titleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_titleLabel]|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:layoutViews]];
    [self.popUpView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_titleView][pickerContainerView][bottomView(1.0)]"
                                                                           options:NSLayoutFormatAlignAllCenterX
                                                                           metrics:nil
                                                                             views:layoutViews]];
    [self.popUpView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomView]-8-[removeButton]-8-|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:layoutViews]];
    [self.popUpView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomView]-8-[saveButton]-8-|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:layoutViews]];
    [self.popUpView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_titleView]|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:layoutViews]];
    
    [self.popUpView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[pickerContainerView]|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:layoutViews]];
    
    [self.popUpView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-4-[bottomView]-4-|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:layoutViews]];
    [self.popUpView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[removeButton][spacer][saveButton]-16-|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:layoutViews]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_popUpView]|"
                                                                               options:0
                                                                               metrics:nil
                                                                                 views:NSDictionaryOfVariableBindings(_popUpView)]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_popUpView]|"
                                                                               options:0
                                                                               metrics:nil
                                                                                 views:NSDictionaryOfVariableBindings(_popUpView)]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.containerView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint: [NSLayoutConstraint constraintWithItem:self.containerView
                                                           attribute:NSLayoutAttributeCenterY
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.view
                                                           attribute:NSLayoutAttributeCenterY
                                                          multiplier:1.0
                                                            constant:0.0]];
    // Apply 'transform' to reduce the size of Pop Up.
    self.popUpView.transform = CGAffineTransformMakeScale(0.85, 0.85);
}

- (void)showPopUpPicker:(UIView *)aView animated:(BOOL)animated
{
    NSLog(@"show picker called");
    self.animationType = PopBounceIn;
    dispatch_async(dispatch_get_main_queue(), ^{
        [aView addSubview:self.view];
        self.titleView.backgroundColor = self.titleColor;
        self.titleLabel.text = self.pickerTitle;
        [self.pickerView selectRow:[self.tableArray indexOfObject:self.selectedValue] inComponent:0 animated:YES];
        if (animated) {
            [self showBounceInAnimation];
        }
    });
}

#pragma mark - UI button methods.
- (void)saveSelection:(id)sender
{
    [self.delegate pickerController:self didSelectValue:self.selectedValue forPicker:self.pickerType];
    [self removeBounceInAnimation];
}

- (void)cancelSelection:(id)sender
{
    [self removeBounceInAnimation];
}

#pragma mark - Pickerview data source methods.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.tableArray count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.tableArray[row];
}

#pragma mark - Pickerview delegate methods.

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.selectedValue = self.tableArray[row];
}

# pragma mark - custom animation methods.
- (void)showZoomAnimation
{
    self.view.alpha = 0;
    self.popUpView.transform = CGAffineTransformMakeScale(0.1, 0.1);
    [UIView animateWithDuration:0.6
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:15.0
                        options:0
                     animations:^{
                         self.view.alpha = 1.0;
                         self.popUpView.transform = CGAffineTransformMakeScale(0.85, 0.85);
                     } completion:nil];
}

- (void)showBounceInAnimation
{
    CGRect finalContainerFrame = self.containerView.frame;
    finalContainerFrame.origin.x = floorf((CGRectGetWidth(self.view.bounds) - CGRectGetWidth(self.containerView.frame))/2.0);
    finalContainerFrame.origin.y = floorf((CGRectGetHeight(self.view.bounds) - CGRectGetHeight(self.containerView.frame))/2.0);
    self.view.alpha = 0.0;
    self.containerView.transform = CGAffineTransformIdentity;
    CGRect startFrame = finalContainerFrame;
    startFrame.origin.y = 0;
    self.containerView.frame = startFrame;
    
    [UIView animateWithDuration:0.7
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:10.0
                        options:0
                     animations:^{
                         self.view.alpha = 1.0;
                         self.containerView.frame = finalContainerFrame;
                     }
                     completion:nil];
}

- (void)removeZoomAnimation
{
    self.view.alpha = 1;
    self.popUpView.transform = CGAffineTransformMakeScale(0.85, 0.85);
    
    [UIView animateWithDuration:self.bounce1Duration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^(void){
                         self.popUpView.transform = CGAffineTransformMakeScale(1.0, 1.0);
                     }
                     completion:^(BOOL finished){
                         
                         [UIView animateWithDuration:self.bounce2Duration
                                               delay:0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^(void){
                                              self.view.alpha = 0.0;
                                              self.popUpView.transform = CGAffineTransformMakeScale(0.1, 0.1);
                                          }completion:^(BOOL finished) {
                                              if (finished) {
                                                  [self.view removeFromSuperview];
                                              }
                                          }];
                     }];
    
}

- (void)removeBounceInAnimation
{
    self.bounce2Duration = 3 * self.bounce1Duration;
    self.view.alpha = 1.0;
    [UIView animateWithDuration:self.bounce1Duration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^(void){
                         CGRect finalFrame = self.containerView.frame;
                         finalFrame.origin.y -= 40.0;
                         self.containerView.frame = finalFrame;
                     }
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:self.bounce2Duration
                                               delay:0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^(void){
                                              CGRect finalFrame = self.containerView.frame;
                                              finalFrame.origin.y = CGRectGetHeight(self.view.bounds);
                                              self.containerView.frame = finalFrame;
                                              self.view.alpha = 0.0;
                                          }completion:^(BOOL finished) {
                                              if (finished) {
                                                  [self.view removeFromSuperview];
                                              }
                                          }];
                     }];
    
}

@end
