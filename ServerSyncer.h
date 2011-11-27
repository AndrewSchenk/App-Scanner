//
//  ServerSyncer.h
//  App Scanner
//
//  Created by Andrew Schenk on 9/16/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ServerSyncer : NSObject {

	NSManagedObjectContext *cmdContext;
	
	@private
	
	NSURLConnection *updateConnection;
	NSMutableData *connData;
}

@property(nonatomic, retain) NSManagedObjectContext* cmdContext;

-(void)startSync;
-(void)startCommandLineSync;

-(void)checkForNewData:(NSDictionary*)dict;
//-(void)checkForNewData:(NSDate*)lastUpdate synchronously:(BOOL)synchron;
-(void)updateDatabaseWithJSON:(NSString*)jsonString;

@end
