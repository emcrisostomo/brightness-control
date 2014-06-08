//
//  BCBrightnessTableController.m
//  Brightness Control
//
//  Created by Enrico Maria Crisostomo on 08/06/14.
//  Copyright (c) 2014 Enrico Maria Crisostomo. All rights reserved.
//

#import "BCBrightnessTableController.h"
#import "BCBrightness.h"

@interface BCBrightnessTableController()

@property (weak) IBOutlet NSArrayController *savedValuesController;
@property (weak) IBOutlet NSTableView *saveTable;

@end

@implementation BCBrightnessTableController

- (instancetype)init
{
    self = [super init];
    
    if (self != nil)
    {
        NSMutableArray *bv = [[NSMutableArray alloc] init];
        BCBrightness *bcBrightness = [[BCBrightness alloc] init];
        bcBrightness.name = @"Initial Name";
        bcBrightness.value = @"Initial Value";
        
        [bv addObject:bcBrightness];
        
        _brightnessValues = bv;
    }
    
    return self;
}

#pragma mark - Table view delegate

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSInteger editedRow = [self.saveTable rowForView:control];
    
    NSLog(@"Edit should end in row %ld.", (long)editedRow);
    
    for (int i=0; i < [self.brightnessValues count]; ++i)
    {
        if (i == editedRow)
            continue;
        
        BCBrightness *currentValue = [self.brightnessValues objectAtIndex:i];
        
        if ([[control stringValue] isEqualToString:currentValue.name])
            return NO;
    }
    
    return YES;
}

#pragma mark - Save Brightness

- (IBAction)saveBrightnessValueWithName:(id)sender
{
    BCBrightness *bcBrightness = [[BCBrightness alloc] init];
    bcBrightness.name = @"Name2";
    bcBrightness.value = @"Value2";
    
    [self.savedValuesController addObject:bcBrightness];
    const NSUInteger index = [self.savedValuesController.arrangedObjects indexOfObject:bcBrightness];
    NSAssert(index != NSNotFound, @"Cannot find recently added object.");
    
    [self.saveTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    NSTableCellView *cellView = [self.saveTable viewAtColumn:0 row:index makeIfNecessary:YES];
    [cellView.textField becomeFirstResponder];
    
    NSLog(@"Index: %lu", index);
    
    for (BCBrightness *val in self.brightnessValues)
    {
        NSLog(@"Brightness values in the array: %@, %@", val.name, val.value);
    }
}

@end
