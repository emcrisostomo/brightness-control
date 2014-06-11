//
//  BCBrightnessTableController.h
//  Brightness Control
//
//  Created by Enrico Maria Crisostomo on 08/06/14.
//  Copyright (c) 2014 Enrico Maria Crisostomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BCBrightnessTableController : NSObject<NSControlTextEditingDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (NSArray *)profileNames;
- (float)getProfileBrightness:(NSString *)profileName;

@end
