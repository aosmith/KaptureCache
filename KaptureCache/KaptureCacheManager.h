//
//  KaptureCacheManager.h
//  KaptureCache
//
//  Created by Alexander Smith on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "NSURLConnection+block.h"
#import "HTTPResponse.h"

@class AppDelegate;

@interface KaptureCacheManager : NSObject {
    NSMutableSet *completeURLS;
    NSMutableSet *pendingURLS;
    NSMutableSet *forceReloadsWaiting;
    
    
    NSMutableDictionary *instanceData;
    NSFileManager *fileManager;
    NSManagedObjectContext *context;
    AppDelegate *appDelegate;
    dispatch_queue_t httpQueue;
    
@private
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    
    pthread_mutex_t mutex;
}
//@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
//@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
//@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSMutableSet *pendingURLS;
//@property (nonatomic, retain, readonly) NSMutableSet *completeURLS;
//@property (nonatomic, retain, readonly) NSMutableDictionary *instanceData;

- (void)flushData;
- (NSURL *)applicationDocumentsDirectory;
- (void)saveContext;
- (void)asyncRequest:(NSURLRequest *)request success:(void(^)(NSData *,NSURLResponse *))successBlock_ failure:(void(^)(NSData *,NSError *))failureBlock_ forceReload:(BOOL)forceReload;
- (void)cacheCleaner;
@end
