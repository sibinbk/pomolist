//
//  FLSettingsController.m
//  Focus8
//
//  Created by Sibin Baby on 27/08/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import "FLSettingsController.h"
#import "JSQSystemSoundPlayer.h"
#import "FLSoundPickerController.h"
#import "UIColor+FlatColors.h"
#import <Social/Social.h>
#import <MessageUI/MessageUI.h>
#import <EAIntroView/EAIntroView.h>

static int const MY_APP_STORE_ID = 1047719965; // Change it with original App ID before uploading Binary

static NSString * const kFLScreenLockKey = @"kFLScreenLockKey";
static NSString * const kFLAlarmSoundKey = @"kFLAlarmSoundKey";

@interface FLSettingsController () <FLSoundPickerControllerDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, EAIntroDelegate>

@property (weak, nonatomic) IBOutlet UILabel *alarmSoundLabel;
@property (weak, nonatomic) IBOutlet UISwitch *preventScreenLockSwitch;

@end

@implementation FLSettingsController
{
    UIView *rootView;
    EAIntroView *_intro;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // using self.navigationController.view - to display EAIntroView above navigation bar
    rootView = self.navigationController.view;
    
    self.alarmSoundLabel.text = self.alarmSound;
    
    // Check if Screen Lock Timer is disabled.
    self.preventScreenLockSwitch.on = [UIApplication sharedApplication].idleTimerDisabled;
}

- (IBAction)preventScreenLock:(UISwitch *)sender
{
    // Disable idle timer to prevent screen lock while app is on foreground.
    [[UIApplication sharedApplication] setIdleTimerDisabled:self.preventScreenLockSwitch.isOn];
    
    // Save Screenlock prevent switch status.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSNumber numberWithBool:self.preventScreenLockSwitch.isOn] forKey:kFLScreenLockKey];
    [userDefaults synchronize];
}

#pragma mark - Settings controller exit method.

- (IBAction)exitSettings:(id)sender
{
    // Save Alarm sound name.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.alarmSound forKey:kFLAlarmSoundKey];
    [userDefaults synchronize];
    
    // Call delegate to inform alarm sound changed.
    [self.delegate settingsController:self didChangeAlarmSound:self.alarmSound];
}

#pragma mark - Sound picker delegate method.

-(void)soundPickerController:(FLSoundPickerController *)controller didSelectSound:(NSString *)sound
{
    self.alarmSoundLabel.text = sound;
    self.alarmSound = sound;
}

#pragma mark - Segue methods.

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"soundPickerSegue"]) {
        FLSoundPickerController *soundPickerController = segue.destinationViewController;
        soundPickerController.delegate = self;
        soundPickerController.selectedSound = self.alarmSound;
    }
}

#pragma mark - Social sharing methods.

- (void)shareItOnfacebook
{
    // Facebook
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]){
        SLComposeViewController *fbPost = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        if (fbPost) {
            [fbPost setInitialText:@"Listee App"];
            [fbPost addURL:[NSURL URLWithString:@"https://itunes.apple.com/app/listee-procrastinators-to/id1047719965?ls=1&mt=8"]];
            [fbPost setCompletionHandler:^(SLComposeViewControllerResult result) {
            }];
            
            [self presentViewController:fbPost animated:YES completion:nil];
        }
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Can't share it!"
                                                                       message:@"You are not logged in to your Facebook account."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                              }];
        [alert addAction:dismissAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)shareItOnTwitter
{
    // Twitter
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]){
        SLComposeViewController *tweet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        if (tweet) {
            [tweet setInitialText:@"Listee App"];
            [tweet addURL:[NSURL URLWithString:@"https://itunes.apple.com/app/listee-procrastinators-to/id1047719965?ls=1&mt=8"]];
            [tweet setCompletionHandler:^(SLComposeViewControllerResult result) {
            }];
            
            [self presentViewController:tweet animated:YES completion:nil];
        }
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Can't tweet it!"
                                                                       message:@"You are not logged in to your Twitter account."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                               }];
        [alert addAction:dismissAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)shareItAsTextMessage
{
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *messageComposeViewController = [[MFMessageComposeViewController alloc] init];
        messageComposeViewController.messageComposeDelegate = self;
        messageComposeViewController.body = @"Hi, check this new productivity app, Listee - https://itunes.apple.com/app/listee-procrastinators-to/id1047719965?ls=1&mt=8";
        [self presentViewController:messageComposeViewController animated:YES completion:nil];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Oops!!"
                                                                       message:@"SMS failed"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                              }];
        [alert addAction:dismissAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)sendFeedBack
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
        mailComposeViewController.mailComposeDelegate = self;
        [mailComposeViewController setToRecipients:@[@"listee.app@gmail.com"]];
        [mailComposeViewController setSubject:@"Feedback"];
        [self presentViewController:mailComposeViewController animated:YES completion:nil];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Oops!!"
                                                                       message:@"Email failed"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                              }];
        [alert addAction:dismissAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

-(void)reviewTheApp
{
    UIAlertController *alertAction = [UIAlertController alertControllerWithTitle:@"Rate Listee"
                                                                         message:@"What do you think about Listee?"
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *LikeAction = [UIAlertAction actionWithTitle:@"Love it"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           [self openAppLink];
                                                           [alertAction dismissViewControllerAnimated:YES completion:nil];
                                                       }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"It's ok"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [self appDislikeAction];
                                                              [alertAction dismissViewControllerAnimated:YES completion:nil];
                                                          }];
    UIAlertAction *dislikeAction = [UIAlertAction actionWithTitle:@"Hate it"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [self appDislikeAction];
                                                              [alertAction dismissViewControllerAnimated:YES completion:nil];
                                                          }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                      style:UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        [alertAction dismissViewControllerAnimated:YES completion:nil];
                                                    }];
    [alertAction addAction:LikeAction];
    [alertAction addAction:okAction];
    [alertAction addAction:dislikeAction];
    [alertAction addAction:cancel];
    
    [self presentViewController:alertAction animated:YES completion:nil];
}

- (void)appDislikeAction
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Rated"
                                                                   message:@"Thanks for rating the app. Would you like to tell us what needs to improve with the app?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [alert dismissViewControllerAnimated:YES completion:nil];
                                                        }];
    UIAlertAction* yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         [self sendFeedBack];
                                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                                     }];
    [alert addAction:noAction];
    [alert addAction:yesAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openAppLink
{
    NSURL *appURL = [NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%d", MY_APP_STORE_ID]];
    
    [[UIApplication sharedApplication] openURL:appURL];
}

#pragma mark - Mail composer delegate method.

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    // Dismiss the mail composer.
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - tableview delegate methods.

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0:
                [self shareItOnfacebook];
                break;
            case 1:
                [self shareItOnTwitter];
                break;
            case 2:
                [self shareItAsTextMessage];
                break;
            default:
                break;
        }
    }
    
    if (indexPath.section == 3 && indexPath.row == 0 ) {
        [self sendFeedBack];
    }
    
    if (indexPath.section == 4 && indexPath.row == 0) {
        [self reviewTheApp];
    }
    
    if (indexPath.section == 5 && indexPath.row == 0) {
        [self showIntroWithCrossDissolve];
    }
}

#pragma mark - Introview.

- (void)showIntroWithCrossDissolve {
    
    NSString *deviceIdentifierString;
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) {
        // iPhone 4
        deviceIdentifierString = @"_4";
    } else if ([[UIScreen mainScreen] bounds].size.height == 568){
        // IPhone 5
        deviceIdentifierString = @"_5";
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) {
        // iPhone 6
        deviceIdentifierString = @"_6";
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) {
        // iPhone 6+
        deviceIdentifierString = @"_6";
    }

    EAIntroPage *page1 = [EAIntroPage page];
    page1.title = @"Welcome to Listee";
    page1.desc = @"Listee is a procrastinator's to do list app. Ever felt a task is time consuming and cannot finish it in time? Listee is here to help you.";
    page1.titleFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0];
    page1.descFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0];
    page1.bgColor = [UIColor flatWisteriaColor];
    NSString *titleImageName1 = [NSString stringWithFormat:@"screen3%@", deviceIdentifierString];
    page1.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:titleImageName1]];
    
    EAIntroPage *page2 = [EAIntroPage page];
    page2.title = @"Procrastinate no more!";
    page2.desc = @"Split task into smaller sessions. Finish one session at a time. Take a break after each session. It's that simple";
    page2.titleFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0];
    page2.descFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0];
    page2.bgColor = [UIColor flatAlizarinColor];
    NSString *titleImageName2 = [NSString stringWithFormat:@"screen1%@", deviceIdentifierString];
    page2.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:titleImageName2]];
    
    EAIntroPage *page3 = [EAIntroPage page];
    page3.title = @"Easy to use. Just swipe!";
    page3.desc = @"Swipe left to Edit or Delete.\n Swipe right to view your progress";
    page3.titleFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0];
    page3.descFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0];
    page3.bgColor = [UIColor flatPeterRiverColor];
    NSString *titleImageName3 = [NSString stringWithFormat:@"screen4%@", deviceIdentifierString];
    page3.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:titleImageName3]];;
    
    EAIntroPage *page4 = [EAIntroPage page];
    page4.title = @"Work on your on terms!";
    page4.desc = @"Listee is highly customizable. Set different time lengths for different tasks. Also choose from a wide variety of themes.";
    page4.titleFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0];
    page4.descFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0];
    page4.bgColor = [UIColor flatTurquoiseColor];
    NSString *titleImageName4 = [NSString stringWithFormat:@"screen2%@", deviceIdentifierString];
    page4.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:titleImageName4]];;
    
    
    EAIntroPage *page5 = [EAIntroPage page];
    page5.title = @"What did you do today?";
    page5.desc = @"Track your progress and get motivated.";
    page5.titleFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0];
    page5.descFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0];
    page5.bgColor = [UIColor flatTurquoiseColor];
    NSString *titleImageName5 = [NSString stringWithFormat:@"screen5%@", deviceIdentifierString];
    page5.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:titleImageName5]];;
    
    EAIntroPage *page6 = [EAIntroPage page];
    page6.title = @"Notifications! Listee can handle it";
    page6.desc = @"Listee will alert you when a session is finished. Even when it is in the background!\n Make sure to enable notifications.";
    page6.titleFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0];
    page6.descFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0];
    page6.bgColor = [UIColor flatTurquoiseColor];
    NSString *titleImageName6 = [NSString stringWithFormat:@"screen6%@", deviceIdentifierString];
    page6.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:titleImageName6]];;
    
    EAIntroView *intro = [[EAIntroView alloc] initWithFrame:rootView.bounds andPages:@[page1, page2, page3, page4, page5, page6]];
    [intro setDelegate:self];
    
    [intro showInView:rootView animateDuration:0.3];
}

@end
