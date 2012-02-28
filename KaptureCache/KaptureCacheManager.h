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
#import "KaptureCacheRequest.h"

@class AppDelegate;

@interface KaptureCacheManager : NSObject {
    NSMutableSet *completeURLS;
    NSMutableSet *pendingURLS;
    NSMutableDictionary *instanceData;
    NSFileManager *fileManager;
    NSManagedObjectContext *context;
    AppDelegate *appDelegate;
    dispatch_queue_t httpQueue;
    
    @private
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}
//@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
//@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
//@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory;
- (void)saveContext;
- (void)asyncRequest:(NSURLRequest *)request success:(void(^)(NSData *,NSURLResponse *))successBlock_ failure:(void(^)(NSData *,NSError *))failureBlock_ forceReload:(BOOL)forceReload;
- (void)coreDataSync;
@end
