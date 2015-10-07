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

static int const MY_APP_STORE_ID = 527097956; // Change it with original App ID before uploading Binary

static NSString * const sampleDescription1 = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
static NSString * const sampleDescription2 = @"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore.";
static NSString * const sampleDescription3 = @"Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.";
static NSString * const sampleDescription4 = @"Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit.";

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
            [fbPost setInitialText:@"ABCD"];
            [fbPost addURL:[NSURL URLWithString:@"https://itunes.apple.com/app/abcd-alphabet-with-phonics/id527097956?mt=8"]];
            [fbPost setCompletionHandler:^(SLComposeViewControllerResult result) {
            }];
            
            [self presentViewController:fbPost animated:YES completion:nil];
        }
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Can't share it!!"
                                                                       message:@"You are not logged in to your Facebook account.  Please login in to your Facebook account first."
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
            [tweet setInitialText:@"ABCD App"];
            [tweet addURL:[NSURL URLWithString:@"https://itunes.apple.com/app/abcd-alphabet-with-phonics/id527097956?mt=8"]];
            [tweet setCompletionHandler:^(SLComposeViewControllerResult result) {
            }];
            
            [self presentViewController:tweet animated:YES completion:nil];
        }
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Can't tweet it!!"
                                                                       message:@"You are not logged in to your Twitter account. Please login in to your Twitter account first."
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
        messageComposeViewController.body = @"Hi, check this new iOS app, https://itunes.apple.com/app/abcd-alphabet-with-phonics/id527097956?mt=8";
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
        [mailComposeViewController setToRecipients:@[@"sibinbk@gmail.com"]];
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

- (void)showIntroWithCrossDissolve {
    EAIntroPage *page1 = [EAIntroPage page];
    page1.title = @"Hello world";
    page1.desc = sampleDescription1;
    page1.bgColor = [UIColor flatWisteriaColor];
//    page1.bgImage = [UIImage imageNamed:@"bg1"];
//    page1.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title1"]];
    
    EAIntroPage *page2 = [EAIntroPage page];
    page2.title = @"This is page 2";
    page2.desc = sampleDescription2;
    page2.bgColor = [UIColor flatAlizarinColor];
//    page2.bgImage = [UIImage imageNamed:@"bg2"];
//    page2.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title2"]];
    
    EAIntroPage *page3 = [EAIntroPage page];
    page3.title = @"This is page 3";
    page3.desc = sampleDescription3;
    page3.bgColor = [UIColor flatPeterRiverColor];
//    page3.bgImage = [UIImage imageNamed:@"bg3"];
//    page3.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title3"]];
    
    EAIntroPage *page4 = [EAIntroPage page];
    page4.title = @"This is page 4";
    page4.desc = sampleDescription4;
    page4.bgColor = [UIColor flatTurquoiseColor];
//    page4.bgImage = [UIImage imageNamed:@"bg4"];
//    page4.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title4"]];
    
    EAIntroView *intro = [[EAIntroView alloc] initWithFrame:rootView.bounds andPages:@[page1,page2,page3,page4]];
    [intro setDelegate:self];
    
    [intro showInView:rootView animateDuration:0.3];
}
@end
