//
//  ModelDataHelpers.h
//  APIScanner
//
//  Created by Andrew Schenk on 9/7/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ModelDataHelpers : NSObject {

}

+ (BOOL)stringIsInDatabase:(NSString*)string context:(NSManagedObjectContext*)context;
+ (NSArray*)getPweepObjectsForSigs:(NSArray*)flagged context:(NSManagedObjectContext*)context;
+ (NSDictionary*)getPweepObjectForSig:(NSDictionary*)flagged context:(NSManagedObjectContext*)context;
+ (NSArray*)searchForPweepsLikeSig:(NSString*)searchSig context:(NSManagedObjectContext*)context;
@end
