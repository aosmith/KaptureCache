//
//  KaptureCacheRequest.h
//  KaptureCache
//
//  Created by Alexander Smith on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface KaptureCacheRequest : NSManagedObject

@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSData *data;
@property (nonatomic, retain) NSDate *updatedAt;

@end
