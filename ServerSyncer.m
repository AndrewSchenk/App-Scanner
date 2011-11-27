//
//  ServerSyncer.m
//  App Scanner
//
//  Created by Andrew Schenk on 9/16/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import "ServerSyncer.h"
#import "APIScannerAppDelegate.h"
#import "Pweep.h"
#import "JSON.h"


@implementation ServerSyncer
@synthesize cmdContext;

-(void)startSync
{
	APIScannerAppDelegate *delegate = (APIScannerAppDelegate*)[[NSApplication sharedApplication] delegate];
	[NSThread detachNewThreadSelector:@selector(triggerDataCheck:)
							 toTarget:self
						   withObject:delegate.threadedContext];
}

-(void)startCommandLineSync
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Pweep" inManagedObjectContext:cmdContext];
	if (!entity) {
		NSLog(@"entity is null.");
	}
	[request setEntity:entity];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"UpdatedAt" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor release];
	
	// Set up a pointer to hold an error, in case the fetch request fails.
	NSError *error = nil;
	NSArray *fetchResults = [cmdContext executeFetchRequest:request error:&error];
	[request release];
	if (fetchResults == nil) {
		// Some amount of error handling here.
	} else if ([fetchResults count] > 1) {
		Pweep *latestUpdated = [fetchResults objectAtIndex:0];
		if (latestUpdated.UpdatedAt) {
			[self checkForNewData:[NSDictionary dictionaryWithObjectsAndKeys:latestUpdated.UpdatedAt, @"updatedAt", [NSNumber numberWithBool:YES], @"sync", nil]];
		}
	}
}

#pragma mark -
#pragma mark Data Check
-(void)triggerDataCheck:(NSManagedObjectContext*)context
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// We need to find the latest from the database
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:@"Pweep" inManagedObjectContext:context]];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"UpdatedAt" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor release];
	
	// Set up a pointer to hold an error, in case the fetch request fails.
	NSError *error = nil;
	NSArray *fetchResults = [context executeFetchRequest:request error:&error];
	[request release];
	if (fetchResults == nil) {
		// Some amount of error handling here.
	} else if ([fetchResults count] > 1) {
		Pweep *latestUpdated = [fetchResults objectAtIndex:0];
		if (latestUpdated.UpdatedAt) {
			[self performSelectorOnMainThread:@selector(checkForNewData:)
								   withObject:[NSDictionary dictionaryWithObjectsAndKeys:latestUpdated.UpdatedAt, @"updatedAt", [NSNumber numberWithBool:NO], @"sync", nil]
								waitUntilDone:NO];
			
		}
	}
	[pool release];
}


//-(void)checkForNewData:(NSDate*)lastUpdate synchronously:(BOOL)synchron
-(void)checkForNewData:(NSDictionary*)dict
{
	// no community feedback in open source version.
}
#pragma mark -
#pragma mark NSURLConnection
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	
	[updateConnection release];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (!connData) {
		connData = [[NSMutableData alloc] initWithCapacity:0];
		[connData retain];
	}
	[connData appendData:data];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *jsonString = [[NSString alloc] initWithData:connData encoding:NSUTF8StringEncoding];
	
	[self updateDatabaseWithJSON:jsonString];
	
	//NSLog(@"jsonString -> %@", jsonString);
	[jsonString release];
	
	[connData release];
	[updateConnection release];
}

-(void)updateDatabaseWithJSON:(NSString*)jsonString
{
	SBJSON *json = [[SBJSON alloc] init];
	APIScannerAppDelegate *delegate = (APIScannerAppDelegate*)[[NSApplication sharedApplication] delegate];
	
	NSManagedObjectContext* useThisContext;
	if (cmdContext) {
		useThisContext = cmdContext;
	} else {
		useThisContext = delegate.managedObjectContext;
	}
	
	NSArray *pweeps = [json objectWithString:jsonString];
	//NSLog(@"Found %i Pweeps...", [pweeps count]);
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
	for(NSDictionary *dict in pweeps) {
		NSDictionary *pweep = [dict objectForKey:@"pweep"];
		
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		[request setEntity:[NSEntityDescription entityForName:@"Pweep" inManagedObjectContext:useThisContext]];
		[request setPredicate:[NSPredicate predicateWithFormat:@"PweepID == %i", [[pweep objectForKey:@"id"] intValue]]]; 
		NSError *fetchError = nil;
		NSArray *results = [useThisContext executeFetchRequest:request error:&fetchError];
		if ([results count] > 0) {
			Pweep* oldPweep = [results objectAtIndex:0];
			
			[oldPweep setLevel:[NSNumber numberWithInt:[[pweep objectForKey:@"level"] intValue]]];
			[oldPweep setLevel_Weight:[NSNumber numberWithFloat:[[pweep objectForKey:@"level_weight"] floatValue]]];
			[oldPweep setSDK_Version:[pweep objectForKey:@"sdk_version"]];
			
			[oldPweep setUpdatedAt:[df dateFromString:[pweep objectForKey:@"updated_at"]]];
			
			NSError *saveError = nil;
			if (![useThisContext save:&saveError]) {
				NSLog(@"Error with db save -> %@", [saveError localizedDescription]);
			} else {
				//NSLog(@"%@ added;", newStation.Name);
			}
		} else {
			// this is a new pweep.  Make an entry in the database for it.
			
			Pweep *newPweep = (Pweep*)[NSEntityDescription insertNewObjectForEntityForName:@"Pweep"
																	inManagedObjectContext:useThisContext];
			
			[newPweep setLevel:[NSNumber numberWithInt:[[pweep objectForKey:@"level"] intValue]]];
			[newPweep setLevel_Weight:[NSNumber numberWithFloat:[[pweep objectForKey:@"level_weight"] floatValue]]];
			[newPweep setSDK_Version:[pweep objectForKey:@"sdk_version"]];
			[newPweep setSignature:[pweep objectForKey:@"signature"]];
			[newPweep setPweepID:[NSNumber numberWithInt:[[pweep objectForKey:@"id"] intValue]]];
			
			[newPweep setUpdatedAt:[df dateFromString:[pweep objectForKey:@"updated_at"]]];
			
			NSError *saveError = nil;
			if (![useThisContext save:&saveError]) {
				NSLog(@"Error with db save -> %@", [saveError localizedDescription]);
			} else {
				//NSLog(@"%@ added;", newStation.Name);
			}
			//NSLog(@"pweep added to database");
		}
	}
	
	//NSLog(@"finished updating database...");
}

-(void)dealloc
{
	[cmdContext release];
	[super dealloc];
}


@end
