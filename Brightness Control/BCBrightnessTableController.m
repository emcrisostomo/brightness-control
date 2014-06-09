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

- (NSArray *)tableSortDescriptors
{
    return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                  ascending:YES]];
}

#pragma mark - Save Brightness

- (IBAction)saveBrightnessValueWithName:(id)sender
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BrightnessValue"
                                                         inManagedObjectContext:self.managedObjectContext];
    
    BrightnessValue *bcBrightness = [[BrightnessValue alloc] initWithEntity:entityDescription
                                             insertIntoManagedObjectContext:self.managedObjectContext];
    bcBrightness.name = @"Name2";
    bcBrightness.brightnessValue = @(self.appDelegate.brightness);
    
    [self.savedValuesController addObject:bcBrightness];
    const NSUInteger index = [self.savedValuesController.arrangedObjects indexOfObject:bcBrightness];
    NSAssert(index != NSNotFound, @"Cannot find recently added object.");
    
    [self.saveTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    NSTableCellView *cellView = [self.saveTable viewAtColumn:0 row:index makeIfNecessary:YES];
    [cellView.textField becomeFirstResponder];
}

@end
