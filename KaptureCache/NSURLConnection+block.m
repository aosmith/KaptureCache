//
//  NSURLConnection+block.m
//  kapture
//
//  Created by Alex Smith on 1/10/12.
//  Copyright (c) 2012 kaptu.re. All rights reserved.
//

#import "NSURLConnection+block.h"
#import "AppDelegate.h"

@implementation NSURLConnection (block)

AppDelegate *appDelegate;

#pragma mark API
+ (void)asyncRequest:(NSURLRequest *)request success:(void(^)(NSData *,NSURLResponse *))successBlock_ failure:(void(^)(NSData *,NSError *))failureBlock_
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (error) {
            failureBlock_(data,error);
        } else {
            successBlock_(data,response);
        }
        
        [pool release];
    });
}
#pragma mark Private
+ (void)backgroundSync:(NSDictionary *)dictionary
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    void(^success)(NSData *,NSURLResponse *) = [dictionary objectForKey:@"success"];
    void(^failure)(NSData *,NSError *) = [dictionary objectForKey:@"failure"];
    NSURLRequest *request = [dictionary objectForKey:@"request"];
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(error)
    {
        failure(data,error);
    }
    else
    {
        success(data,response);
    }
    [pool release];
}

@end
