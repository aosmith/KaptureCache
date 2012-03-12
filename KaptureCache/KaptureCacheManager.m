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

//@synthesize completeURLS;
@synthesize pendingURLS;
//@synthesize instanceData;

-(void)flushData {
    pthread_mutex_lock(&mutex);
    [instanceData removeAllObjects];
    pthread_mutex_unlock(&mutex);
}

-(id)init
{
    self = [super init];
    if (self) {
        appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        completeURLS = [[NSMutableSet alloc] init];
        pendingURLS = [[NSMutableSet alloc] init];
        instanceData = [[NSMutableDictionary alloc] init];
        //fileManager = (NSFileManager *)[[NSFileManager alloc] init];
        httpQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        context = [self managedObjectContext];
        //[self cacheCleaner];
        
        pthread_mutex_init(&mutex, NULL);
    }
    return self;
}

-(void)asyncRequest:(NSURLRequest *)request success:(void (^)(NSData *, NSURLResponse *))successBlock_ failure:(void (^)(NSData *, NSError *))failureBlock_ forceReload:(BOOL)forceReload{
    //NSLog(@"Instance Data:\n%@\n------------------------\n", instanceData);
    dispatch_async(httpQueue, ^{
        Boolean fromForceReloadQueue = NO;
        Boolean reload = forceReload;
        CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
        NSString *mainURL = [NSString stringWithFormat:@"%@", request.URL];
        //wait cycle for pending operations
        //int waitCycleCounter = 0;
        // NSLog(@"\nRequest: %@\nObjects in primary cache:\n%@", request.URL, [instanceData allKeys]);
        BOOL wait = NO;
        while ([pendingURLS containsObject:mainURL] || [pendingURLS count] > 50) {
            if (wait == NO)
                NSLog(@"KaptureCache waiting: %@", request.URL);
            wait = YES;
            [NSThread sleepForTimeInterval:1.0f];
            pthread_mutex_lock(&mutex);
            if ([forceReloadsWaiting containsObject:mainURL]) {
                reload = NO;
            } else if (reload == YES) {
                [forceReloadsWaiting addObject:mainURL];
                fromForceReloadQueue = YES;
            }
            pthread_mutex_unlock(&mutex);
        }
        pthread_mutex_lock(&mutex);
        [pendingURLS addObject:mainURL];
        pthread_mutex_unlock(&mutex);
        if (reload == NO) {
            if ([instanceData objectForKey:mainURL] == nil) {
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"url == %@", mainURL]];
                [fetchRequest setFetchLimit:1];
                [fetchRequest setEntity:[NSEntityDescription entityForName:@"HTTPResponse" inManagedObjectContext:context]];
                NSError *error = [[NSError alloc] init];
                NSLog(@"Starting fetch");
                pthread_mutex_lock(&mutex);
                NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
                pthread_mutex_unlock(&mutex);
                NSLog(@"Done fetching");
                if ([fetchedObjects count] > 0) {
                    NSLog(@"Secondary cache hit");
                    //Secondary cache hit
                    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
                    NSLog(@"KaptureCache secondary hit (%f):%@",(endTime - startTime),mainURL);
                    HTTPResponse *cacheHit = [fetchedObjects objectAtIndex:0];
                    [instanceData setObject:cacheHit forKey:mainURL];
                    if ([cacheHit data] == nil) {
                        NSData *storedData = [[NSData alloc] initWithContentsOfFile:[cacheHit attachedFilePath]];
                        successBlock_(storedData, nil);
                        if ([storedData length] < 20000) {
                            reload = YES;
                        }
                    } else {
                        successBlock_([cacheHit data], nil);
                    }
                } else {
                    reload = YES;
                    NSLog(@"KaptureCache miss: %@", mainURL);
                }
            } else {
                CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
                NSLog(@"KaptureCache primary hit (%f):%@",(endTime - startTime),mainURL);
                HTTPResponse *cacheRecord = [instanceData objectForKey:mainURL];
                if ([cacheRecord data] == nil) {
                    NSData *fileData = [[NSData alloc] initWithContentsOfFile:[cacheRecord attachedFilePath]];
                    if ([fileData length] < 20000) {
                        reload = YES;
                    } else {
                        successBlock_(fileData, nil);
                    }
                } else {
                    successBlock_([cacheRecord data], nil);
                }
            }
        }
        
        if (reload == YES) {
            NSURLResponse *response;
            NSError *error;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            if (error) {
                NSLog(@"KaptureCache Network Error: %@", error);
                failureBlock_(data,error);
            } else {
                pthread_mutex_lock(&mutex);
                HTTPResponse *cacheEntity = [NSEntityDescription insertNewObjectForEntityForName:@"HTTPResponse" inManagedObjectContext:context];
                [cacheEntity setValue:mainURL forKey:@"url"];
                if ([data length] > 20000) {
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
                    NSString *documentsDirectory = [paths objectAtIndex:0];
                    NSString *filename = [[mainURL stringByReplacingOccurrencesOfString:@"/" withString:@""] substringFromIndex:([mainURL length] > 32 ? [mainURL length] - 32 : 0)];
                    NSString *file = [documentsDirectory stringByAppendingPathComponent:filename];
                    [data writeToFile:file atomically:YES];
                    [cacheEntity setValue:nil forKey:@"data"];
                    [cacheEntity setValue:[documentsDirectory stringByAppendingPathComponent:filename] forKey:@"attachedFilePath"];
                    NSLog(@"Data size for url: %@ larger than 20k, saving to file", mainURL);
                } else {
                    [cacheEntity setValue:nil forKey:@"attachedFilePath"];
                    [cacheEntity setValue:data forKey:@"data"];
                }
                [cacheEntity setValue:[NSDate date] forKey:@"updated"];
                
                [instanceData setObject:cacheEntity forKey:mainURL];
                NSLog(@"KaptureCache miss complete: %@", mainURL);
                @try {
                    [context save:&error];
                }
                @catch (NSException *exception) {
                    pthread_mutex_unlock(&mutex);
                    NSLog(@"KaptureCache retrying db write");
                    [NSThread sleepForTimeInterval:10.0f];
                    pthread_mutex_lock(&mutex);
                    
                }
                @finally {
                    [context save:&error];
                    pthread_mutex_unlock(&mutex);
                }
                if (error) {
                    NSLog(@"%@", error);
                }
                successBlock_(data,response);
            }
        }
        pthread_mutex_lock(&mutex);
        [pendingURLS removeObject:mainURL];
        if (fromForceReloadQueue == YES) {
            [forceReloadsWaiting removeObject:mainURL];
        }
        pthread_mutex_unlock(&mutex);
    });
}


- (void)cacheCleaner {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSDate *cacheLimit = [NSDate dateWithTimeInterval:(-1 * 60 * 60 *24 * 7) sinceDate:[NSDate date]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"updated < %@", cacheLimit]];
    //[fetchRequest setFetchLimit:];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"HTTPResponse" inManagedObjectContext:context]];
    NSError *error = [[NSError alloc] init];
    NSLog(@"Cleaning old cache entries...");
    pthread_mutex_lock(&mutex);
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    NSLog(@"Done fetching.");
    for (int i = 0; i < [fetchedObjects count]; i++) {
        HTTPResponse *cacheHit = [fetchedObjects objectAtIndex:i];
        if ([cacheHit data] == nil) {
            NSFileManager *fileMgr = [NSFileManager defaultManager];
            [fileMgr removeItemAtPath:[cacheHit attachedFilePath] error:&error];
        }
        NSLog(@"Removing: %@", cacheHit);
        [context deleteObject:[fetchedObjects objectAtIndex:i]];
    }
    pthread_mutex_unlock(&mutex);
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
    
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"kaptureCacheDb.sqlite"];
    
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
