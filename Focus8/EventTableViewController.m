//
//  EventTableViewController.m
//  Focus8
//
//  Created by Sibin Baby on 7/03/2015.
//  Copyright (c) 2015 FocusApps. All rights reserved.
//

#import "EventTableViewController.h"
#import "AppDelegate.h"
#import "FLEventCell.h"
#import "ColorUtils.h"
#import "Task.h"
#import "Event.h"

@interface EventTableViewController () <NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSFetchedResultsController *fetchedResultsController;
@end

@implementation EventTableViewController
@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // A little trick for removing the cell separators
    self.tableView.tableFooterView = [UIView new];
    
    NSError *error = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error in loading data", @"Error in loading data")
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Error was: %@, quitting.", @"Error was: %@, quitting."), [error localizedDescription]]
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction)dismissView:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 68.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [[_fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"EventCell";
    FLEventCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...

    Event *event = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    Task *task = event.task;
    
    cell.nameLabel.text = task.name;
    cell.durationLabel.attributedText = [self timeStringFromDuration:(int)[event.totalTaskTime integerValue]];
    cell.sessionCountLabel.attributedText = [self sessionCountStringFromCount:[event.totalSessionCount integerValue]];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

#pragma mark - Tableview delegate.

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error in saving data", @"Error in saving data")
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"Error was: %@, quitting.", @"Error was: %@, quitting."), [error localizedDescription]]
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    header.tintColor = [UIColor whiteColor];
    header.textLabel.textColor = [UIColor blackColor];
    header.textLabel.font = [UIFont systemFontOfSize:16];
    CGRect headerFrame = header.frame;
    header.textLabel.frame = headerFrame;
    header.textLabel.textAlignment = NSTextAlignmentCenter;
}

#pragma mark - Fetched Results Controller Section

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:30];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"finishTime" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    fetchRequest.sortDescriptors = sortDescriptors;
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:self.managedObjectContext
                                                                      sectionNameKeyPath:@"dateSection"
                                                                               cacheName:nil];
    _fetchedResultsController.delegate = self;
    return _fetchedResultsController;
}

#pragma mark - Fetched Results Controller Delegates

// Return AppDelegate's ManagedObjectContext.
-(NSManagedObjectContext *)managedObjectContext
{
    return [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            NSLog(@"Inserting");
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            NSLog(@"Deleting");
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            NSLog(@"Updating");
//            [self configureCell:(UITableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            //            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            //            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            //            [tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        case NSFetchedResultsChangeMove:
            NSLog(@"Moving");
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationRight];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
            break;
    }
}

- (NSMutableAttributedString *)sessionCountStringFromCount:(NSInteger)count
{
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *firstStringAttributes = @{
                                            NSFontAttributeName:[UIFont systemFontOfSize:20 weight:UIFontWeightLight],
                                            NSForegroundColorAttributeName:[UIColor blackColor],
                                            NSParagraphStyleAttributeName :paragraphStyle
                                            };
    NSDictionary *secondStringAttributes = @{
                                             NSFontAttributeName:[UIFont systemFontOfSize:16 weight:UIFontWeightLight],
                                             NSForegroundColorAttributeName:[UIColor blackColor],
                                             NSParagraphStyleAttributeName :paragraphStyle
                                             };
    NSString *firstString = [NSString stringWithFormat:@"%ld", (long)count];
    
    NSString *secondString;
    
    if (count > 1) {
        secondString = @"sessions";
    } else {
        secondString = @"session";
    }
    
    NSString *combinedString = [NSString stringWithFormat:@"%@%@", firstString, secondString];
    NSMutableAttributedString *modifiedString = [[NSMutableAttributedString alloc] initWithString:combinedString];
    [modifiedString setAttributes:firstStringAttributes range:[combinedString rangeOfString:firstString]];
    [modifiedString setAttributes:secondStringAttributes range:[combinedString rangeOfString:secondString]];
    
    return modifiedString;
}

- (NSMutableAttributedString *)timeStringFromDuration:(int)seconds
{
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *timeAttributes = @{
                                     NSFontAttributeName:[UIFont systemFontOfSize:24 weight:UIFontWeightMedium],
                                     NSForegroundColorAttributeName:[UIColor colorWithString:@"3498DB"],
                                     NSParagraphStyleAttributeName :paragraphStyle
                                     };
    NSDictionary *subAttributes = @{
                                    NSFontAttributeName:[UIFont systemFontOfSize:20 weight:UIFontWeightMedium],
                                    NSForegroundColorAttributeName:[UIColor colorWithString:@"3498DB"],
                                    NSParagraphStyleAttributeName :paragraphStyle
                                    };
    
    int remainingSeconds = seconds;
    
    int hours = remainingSeconds / 3600;
    
    remainingSeconds = remainingSeconds - hours * 3600;
    
    int minutes = remainingSeconds / 60;
    
    remainingSeconds = remainingSeconds - minutes * 60;
    
    NSString *minuteString = @"min";
    NSString *hourString = @"hr";
    
    if (hours > 0) {
        if (minutes > 0) {
            NSString *timeString = [NSString stringWithFormat:@"%i%@ %i%@", hours, hourString, minutes, minuteString];
            NSMutableAttributedString *modifiedString = [[NSMutableAttributedString alloc] initWithString:timeString attributes:timeAttributes];
            [modifiedString setAttributes:subAttributes range:[timeString rangeOfString:minuteString]];
            [modifiedString setAttributes:subAttributes range:[timeString rangeOfString:hourString]];
            return modifiedString;
        } else {
            NSString *timeString = [NSString stringWithFormat:@"%i%@", hours, hourString];
            NSMutableAttributedString *modifiedString = [[NSMutableAttributedString alloc] initWithString:timeString attributes:timeAttributes];
            [modifiedString setAttributes:subAttributes range:[timeString rangeOfString:hourString]];
            return modifiedString;
        }
    } else {
        NSString *timeString = [NSString stringWithFormat:@"%i%@", minutes, minuteString];
        NSMutableAttributedString *modifiedString = [[NSMutableAttributedString alloc] initWithString:timeString attributes:timeAttributes];
        [modifiedString setAttributes:subAttributes range:[timeString rangeOfString:minuteString]];
        return modifiedString;
    }
}

@end
