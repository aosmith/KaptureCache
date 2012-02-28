//
//  KaptureCacheRequest.m
//  KaptureCache
//
//  Created by Alexander Smith on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KaptureCacheRequest.h"


@implementation KaptureCacheRequest

@dynamic url;
@dynamic data;
@dynamic updatedAt;

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (NSString *)url {
    return self.url;
}
@end
