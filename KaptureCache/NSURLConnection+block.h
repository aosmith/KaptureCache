//
//  NSURLConnection+block.h
//  kapture
//
//  Created by Alex Smith on 1/10/12.
//  Copyright (c) 2012 kaptu.re. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AppDelegate;

@interface NSURLConnection (block)
    #pragma mark Class API Extensions
    + (void)asyncRequest:(NSURLRequest *)request success:(void(^)(NSData *,NSURLResponse *))successBlock_ failure:(void(^)(NSData *,NSError *))failureBlock_;
@end
