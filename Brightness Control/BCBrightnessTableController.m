//
//  BCBrightnessTableController.m
//  Brightness Control
//
//  Created by Enrico Maria Crisostomo on 08/06/14.
//  Copyright (c) 2014 Enrico Maria Crisostomo. All rights reserved.
//

#import "BCBrightnessTableController.h"
#import "BCAppDelegate.h"
#import "BrightnessValue.h"

@interface BCBrightnessTableController()

@property (weak) IBOutlet NSArrayController *savedValuesController;
@property (weak) IBOutlet NSTableView *saveTable;
@property (weak) IBOutlet BCAppDelegate *appDelegate;

@end

@implementation BCBrightnessTableController
{
    BOOL savedValuesFetched;
}

#pragma mark - Table view delegate

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSInteger editedRow = [self.saveTable rowForView:control];
    
    // Using the auto rearrange feature of the NSArrayController causes
    // textShouldEndEditing to be called twice when a record is edited:
    //   * The first time when the edit operation is done.
    //   * The second time when the row is being animated to the new position,
    //     in which case -1 is returned by rowForView.
    if (editedRow == -1)
        return YES;
    
    NSLog(@"Edit should end in row %ld.", (long)editedRow);
    
    for (int i=0; i < [self.savedValuesController.arrangedObjects count]; ++i)
    {
        if (i == editedRow)
            continue;
        
        BrightnessValue *currentValue = [self.savedValuesController.arrangedObjects objectAtIndex:i];
        
        if ([[control stringValue] isEqualToString:currentValue.name])
            return NO;
    }

    return YES;
}

#pragma mark - Save Brightness

- (IBAction)saveBrightnessValueWithName:(id)sender
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BrightnessValue"
                                                         inManagedObjectContext:self.managedObjectContext];
    
    BrightnessValue *bcBrightness = [[BrightnessValue alloc] initWithEntity:entityDescription
                                             insertIntoManagedObjectContext:self.managedObjectContext];
    bcBrightness.name = NSLocalizedString(@"newProfileName", nil);
    bcBrightness.brightnessValue = @(self.appDelegate.brightness);
    
    [self.savedValuesController addObject:bcBrightness];
    const NSUInteger index = [self.savedValuesController.arrangedObjects indexOfObject:bcBrightness];
    NSAssert(index != NSNotFound, @"Cannot find recently added object.");
    
    [self.saveTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    NSTableCellView *cellView = [self.saveTable viewAtColumn:0 row:index makeIfNecessary:YES];
    [cellView.textField becomeFirstResponder];
}

- (IBAction)restoreBrightness:(id)sender
{
    BrightnessValue *selectedObject = [self.savedValuesController.selectedObjects firstObject];
    self.appDelegate.brightness = [selectedObject.brightnessValue floatValue];
}

- (NSArray *)profileNames
{
    NSMutableArray *names = [[NSMutableArray alloc] init];
    
    for (BrightnessValue *bv in [self.savedValuesController arrangedObjects])
    {
        [names addObject:bv.name];
    }
    
    return names;
}

- (void)loadValues
{
    if (!savedValuesFetched)
    {
        NSError *error;
        [self.savedValuesController fetchWithRequest:nil merge:NO error:&error];
        savedValuesFetched = YES;
    }
}

- (BOOL)existsProfile:(NSString *)profileName
{
    [self loadValues];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.name == %@", profileName];
    NSArray *profilesByName = [[self.savedValuesController arrangedObjects] filteredArrayUsingPredicate:predicate];
    
    NSAssert([profilesByName count] <= 1, @"Duplicate profile name.");
    
    return ([profilesByName count] > 0);
}

- (float)getProfileBrightness:(NSString *)profileName
{
    [self loadValues];
    
    if (profileName == nil) return -1;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.name == %@", profileName];
    NSArray *profilesByName = [[self.savedValuesController arrangedObjects] filteredArrayUsingPredicate:predicate];
    
    if ([profilesByName count] == 0) return -1;
    
    NSAssert([profilesByName count] == 1, @"The profile searched for cannot be found.");
    
    return [[[profilesByName firstObject] brightnessValue] floatValue];
}

@end
