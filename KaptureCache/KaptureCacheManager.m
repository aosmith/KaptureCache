//
//  KaptureCacheManager.m
//  KaptureCache
//
//  Created by Alexander Smith on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KaptureCacheManager.h"

#import "AppDelegate.h"

@implementation KaptureCacheManager

-(id)init
{
    self = [super init];
    if (self) {
        appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        completeURLS = [[NSMutableSet alloc] init];
        pendingURLS = [[NSMutableSet alloc] init];
        instanceData = [[NSMutableDictionary alloc] init];
        //fileManager = (NSFileManager *)[[NSFileManager alloc] init];
        httpQueue = dispatch_queue_create("com.kapture.httpQueue", NULL);
        context = [self managedObjectContext];
    }
    return self;
}

-(void)asyncRequest:(NSURLRequest *)request success:(void (^)(NSData *, NSURLResponse *))successBlock_ failure:(void (^)(NSData *, NSError *))failureBlock_ forceReload:(BOOL)forceReload{
    dispatch_async(httpQueue, ^{
        CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
        NSString *mainURL = [NSString stringWithFormat:@"%@", request.mainDocumentURL];
        mainURL = [NSString stringWithFormat:@"%@", request.URL];
        //wait cycle for pending operations
        int waitCycleCounter = 0;
        while ([pendingURLS containsObject:mainURL]) {
            if (waitCycleCounter == 60) {
                return;
            } else {
                NSLog(@"wait block");
                [NSThread sleepForTimeInterval:0.5];
            }
            waitCycleCounter++;
        }
        [pendingURLS addObject:mainURL];

        //Force reload
        if (forceReload == YES || forceReload == true) {
            NSLog(@"force reloading: %@", mainURL);
            [NSURLConnection asyncRequest:request success:^(NSData *data, NSURLResponse *response) {
                successBlock_(data, response);
                KaptureCacheRequest *cacheRecord = [[KaptureCacheRequest alloc] init];
                cacheRecord.url = mainURL;
                cacheRecord.data = data;
                cacheRecord.updatedAt = [NSDate date];
                [pendingURLS removeObject:mainURL];
            } failure:^(NSData *data, NSError *error) {
                failureBlock_(data, error);
            }];
        //Regular cache
        } else {
            if ([instanceData objectForKey:mainURL] == nil) {
                //try to fetch from core data
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"url == %@", mainURL]];
                [fetchRequest setFetchLimit:1];
                [fetchRequest setEntity:[NSEntityDescription entityForName:@"KaptureCacheRequest" inManagedObjectContext:context]];
                NSError *error = [[NSError alloc] init];
                NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
                if ([fetchedObjects count] > 0) {
                    KaptureCacheRequest *cacheHit = [fetchedObjects objectAtIndex:0];
                    [instanceData setValue:cacheHit forKey:mainURL];
                    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
                    NSLog(@"Secondary cache hit (%f):%@",(endTime - startTime),mainURL);
                    successBlock_([cacheHit data], nil);
                    [pendingURLS removeObject:mainURL];
                } else {
                    //fetch via http
                    [NSURLConnection asyncRequest:request success:^(NSData *data, NSURLResponse *response) {
                        [instanceData setValue:data forKey:mainURL];
                        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
                        NSLog(@"Secondary cache hit (%f):%@",(endTime - startTime),mainURL);
                        successBlock_(data, response);
                        
                        KaptureCacheRequest *cacheEntity = [NSEntityDescription insertNewObjectForEntityForName:@"KaptureCacheRequest" inManagedObjectContext:context];
                        [cacheEntity setValue:mainURL forKey:@"url"];
                        [cacheEntity setValue:data forKey:@"data"];
                        [cacheEntity setValue:[NSDate date] forKey:@"updatedAt"];
                        
                        NSError *error = nil;
                        [context save:&error];
                        if (error) {
                            NSLog(@"%@", error);
                        }
                        
                        [pendingURLS removeObject:mainURL];
                        
                        
                    } failure:^(NSData *data, NSError *error) {
                    }];
                }
            } else {
                //cache hit
                CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
                NSLog(@"Primary cache hit (%f):%@",(endTime - startTime),mainURL);
                [pendingURLS removeObject:mainURL];
                KaptureCacheRequest *cacheRecord = [instanceData objectForKey:mainURL];
                successBlock_([cacheRecord data], nil);
            }
        }
    });
}


//Core data sync thread


//Core data

- (void)saveContext
{
    
    NSError *error = nil;
    NSManagedObjectContext *objectContext = self.managedObjectContext;
    if (objectContext != nil)
    {
        if ([objectContext hasChanges] && ![objectContext save:&error])
        {
            // add error handling here
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (NSManagedObjectContext *)managedObjectContext
{
    
    if (managedObjectContext != nil)
    {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel != nil)
    {
        return managedObjectModel;
    }
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return managedObjectModel;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    
    if (persistentStoreCoordinator != nil)
    {
        return persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CoreDataTabBarTutorial.sqlite"];
    
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }  
    
    return persistentStoreCoordinator;
}




@end
