//
//  FLDatePickerController.m
//  Focus8
//
//  Created by Sibin Baby on 27/05/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import "FLDatePickerController.h"
#import "UIColor+FlatColors.h"
#import "Focus8-Swift.h"

typedef NS_ENUM(NSInteger, PopAnimationType) {
    PopZoom,
    PopBounceIn
};

@interface FLDatePickerController ()

@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) UIView *popUpView;
@property (strong, nonatomic) UIView *titleView;
@property (strong, nonatomic) UILabel *pickerLabel;
@property (strong, nonatomic) UIDatePicker *datePicker;
@property (nonatomic) NSTimeInterval bounce1Duration;
@property (nonatomic) NSTimeInterval bounce2Duration;
@property (strong, nonatomic)NSDateFormatter *formatter;
@property (nonatomic) PopAnimationType animationType;

@end

@implementation FLDatePickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
 
    //Setup date formatter
    self.formatter = [[NSDateFormatter alloc] init];
    NSString *format = [NSDateFormatter dateFormatFromTemplate:@"MMM d, yyyy hh:mm a" options:0 locale:[NSLocale currentLocale]];
    [self.formatter setDateFormat:format];

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
    UILabel* titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = @"Reminder";
    [self.titleView addSubview:titleLabel];
    
    // date picker label
    self.pickerLabel = [[UILabel alloc] init];
    self.pickerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.pickerLabel.backgroundColor = [UIColor clearColor];
    self.pickerLabel.textColor = [UIColor whiteColor];
    self.pickerLabel.font = [UIFont systemFontOfSize:20.0];
    self.pickerLabel.textAlignment = NSTextAlignmentCenter;
    [self.titleView addSubview:self.pickerLabel];

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
    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.translatesAutoresizingMaskIntoConstraints = NO;
//    self.datePicker.minuteInterval = 5;
    self.datePicker.backgroundColor = [UIColor whiteColor];
    [self.datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
    [pickerContainerView addSubview:self.datePicker];
    
    // Cancel button for picker.
    UIButton* removeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    removeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [removeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [removeButton setTitleColor:[[removeButton titleColorForState:UIControlStateNormal] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
    removeButton.titleLabel.font = [UIFont systemFontOfSize:20.0];
    [removeButton setTitle:@"Remove" forState:UIControlStateNormal];
    [removeButton addTarget:self action:@selector(removeReminder:) forControlEvents:UIControlEventTouchUpInside];
    [self.popUpView addSubview:removeButton];
    
    // Save button for picker.
    UIButton* saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [saveButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [saveButton setTitleColor:[[removeButton titleColorForState:UIControlStateNormal] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
    saveButton.titleLabel.font = [UIFont systemFontOfSize:20.0];
    [saveButton setTitle:@"Save" forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(saveReminder:) forControlEvents:UIControlEventTouchUpInside];
    [self.popUpView addSubview:saveButton];
    
    // Padding views.
    UIView *spacer = [UIView new];
    spacer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.popUpView addSubview:spacer];
    
    NSDictionary* layoutViews = NSDictionaryOfVariableBindings(_containerView, _popUpView, _titleView, bottomView, pickerContainerView, _datePicker, removeButton, saveButton, titleLabel, _pickerLabel, spacer);
    
    [pickerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_datePicker]|"
                                                                                options:NSLayoutFormatAlignAllCenterX
                                                                                metrics:nil
                                                                                  views:layoutViews]];
    [pickerContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_datePicker]|"
                                                                                options:NSLayoutFormatAlignAllCenterY
                                                                                metrics:nil
                                                                                  views:layoutViews]];
    
    [self.titleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[titleLabel]-[_pickerLabel]-8-|"
                                                                           options:NSLayoutFormatAlignAllCenterX
                                                                           metrics:nil
                                                                             views:layoutViews]];
    [self.titleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[titleLabel]|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:layoutViews]];
    [self.titleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_pickerLabel]|"
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
    [self.containerView addConstraints:[NSLayoutConstraint
                                      constraintsWithVisualFormat:@"H:|[_popUpView]|"
                                      options:0
                                      metrics:nil
                                      views:NSDictionaryOfVariableBindings(_popUpView)]];
    [self.containerView addConstraints:[NSLayoutConstraint
                                      constraintsWithVisualFormat:@"V:|[_popUpView]|"
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
    
    
    self.popUpView.transform = CGAffineTransformMakeScale(0.85, 0.85);
}

- (void)shoWDatePickerOnView:(UIView *)aView animated:(BOOL)animated
{
    NSLog(@"show picker called");
    self.animationType = PopBounceIn;
    dispatch_async(dispatch_get_main_queue(), ^{
        [aView addSubview:self.view];
        if (self.reminderDate) {
            self.pickerLabel.text = [self.formatter stringFromDate:self.reminderDate];
            [self.datePicker setDate:self.reminderDate animated:YES];
        }
        self.titleView.backgroundColor = self.titleColor;
        if (animated) {
            [self showBounceInAnimation];
        }
    });
}

#pragma mark - UI button methods.
- (void)saveReminder:(id)sender
{
    [self.delegate pickerController:self reminderAdded:self.datePicker.date];
    
    [self removeBounceInAnimation];
}

- (void)removeReminder:(id)sender
{
    [self.delegate pickerController:self reminderRemoved:YES];
    
    [self removeBounceInAnimation];
}

#pragma mark - UIDatePicker delegate methods.

- (void)dateChanged:(id)sender
{
    NSLog(@"date changed");
    self.pickerLabel.text = [self.formatter stringFromDate:self.datePicker.date];
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
