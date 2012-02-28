//
//  AppDelegate.h
//  KaptureCache
//
//  Created by Alexander Smith on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "KaptureCacheManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    NSManagedObjectContext *context;
}

@property (strong, nonatomic) UIWindow *window;

@end
