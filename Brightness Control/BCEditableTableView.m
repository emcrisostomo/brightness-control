//
//  BCEditableTableView.m
//  Brightness Control
//
//  Created by Enrico Maria Crisostomo on 08/07/14.
//  Copyright (c) 2014 Enrico Maria Crisostomo. All rights reserved.
//

#import "BCEditableTableView.h"

@implementation BCEditableTableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)cancelOperation:(id)sender
{
    NSLog(@"ESC");
}

@end
