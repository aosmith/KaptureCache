//
//  HTTPResponse.h
//  kapture
//
//  Created by Alexander Smith on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface HTTPResponse : NSManagedObject

@property (nonatomic, retain) NSString * attachedFilePath;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSDate * updated;
@property (nonatomic, retain) NSString * url;

@end
