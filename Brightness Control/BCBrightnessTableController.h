//
//  BCBrightnessTableController.h
//  Brightness Control
//
//  Created by Enrico Maria Crisostomo on 08/06/14.
//  Copyright (c) 2014 Enrico Maria Crisostomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BCBrightnessTableController : NSObject<NSControlTextEditingDelegate>

// Left in header file because IB complains about missing key path otherwise.
@property NSMutableArray *brightnessValues;

@end
