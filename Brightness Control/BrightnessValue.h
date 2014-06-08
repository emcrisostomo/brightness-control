//
//  BrightnessValue.h
//  Brightness Control
//
//  Created by Enrico Maria Crisostomo on 08/06/14.
//  Copyright (c) 2014 Enrico Maria Crisostomo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface BrightnessValue : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * brightnessValue;

@end
