//
//  ModelDataHelpers.m
//  APIScanner
//
//  Created by Andrew Schenk on 9/7/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import "ModelDataHelpers.h"
#import "Pweep.h"
#import "Constants.h"

@implementation ModelDataHelpers


+ (BOOL)stringIsInDatabase:(NSString*)string context:(NSManagedObjectContext*)context
{
	BOOL wasFound = NO;
	
	NSFetchRequest *req = [[NSFetchRequest alloc] init];
	[req setEntity:[NSEntityDescription entityForName:@"Pweep" inManagedObjectContext:context]];
	int percentage = 30;
	if([[NSUserDefaults standardUserDefaults] boolForKey:kPrefFilterSet]) {
		percentage = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFilter];
	}
	[req setPredicate:[NSPredicate predicateWithFormat:@"Signature == %@ AND Level >= %i", string, percentage]];
	
	NSError *fetchError = nil;
	NSArray *results = [context executeFetchRequest:req error:&fetchError];
	[req release];
	if (fetchError) {
		NSLog(@"Error Fetching Method From Database... %@", [fetchError localizedDescription]);
	} else {
		if ([results count] > 0) {
			wasFound = YES;
		}
	}

	
	return wasFound;
}

+ (NSArray*)getPweepObjectsForSigs:(NSArray*)flagged context:(NSManagedObjectContext*)context
{
	NSMutableArray *pweeps = [[[NSMutableArray alloc] initWithCapacity:[flagged count]] autorelease];
	
	for(NSDictionary* dict in flagged)
	{
		NSFetchRequest *req = [[NSFetchRequest alloc] init];
		[req setEntity:[NSEntityDescription entityForName:@"Pweep" inManagedObjectContext:context]];
		[req setPredicate:[NSPredicate predicateWithFormat:@"Signature == %@", [dict objectForKey:@"Sig"]]];
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
											initWithKey:@"Level" ascending:NO];
		[req setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		[sortDescriptor release];
		
		NSError *fetchError = nil;
		NSArray *results = [context executeFetchRequest:req error:&fetchError];
		[req release];
		if (fetchError) {
			NSLog(@"Error Fetching Method From Database... %@", [fetchError localizedDescription]);
		} else {
			if ([results count] > 0) {
				NSDictionary *newDict = [NSDictionary dictionaryWithObjectsAndKeys:[dict objectForKey:@"Class"],
										 @"Class", [dict objectForKey:@"Sig"], @"Sig", [results objectAtIndex:0], @"Pweep", nil];
				
				[pweeps addObject:newDict];
			}
		}
	}
	
	return pweeps;
}

+ (NSDictionary*)getPweepObjectForSig:(NSDictionary*)flagged context:(NSManagedObjectContext*)context
{
	NSFetchRequest *req = [[NSFetchRequest alloc] init];
	[req setEntity:[NSEntityDescription entityForName:@"Pweep" inManagedObjectContext:context]];
	[req setPredicate:[NSPredicate predicateWithFormat:@"Signature == %@", [flagged objectForKey:@"Sig"]]];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
										initWithKey:@"Level" ascending:NO];
	[req setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[sortDescriptor release];
	
	NSError *fetchError = nil;
	NSArray *results = [context executeFetchRequest:req error:&fetchError];
	[req release];
	if (fetchError) {
		NSLog(@"Error Fetching Method From Database... %@", [fetchError localizedDescription]);
	} else {
		if ([results count] > 0) {
			return [NSDictionary dictionaryWithObjectsAndKeys:[flagged objectForKey:@"Class"],
					@"Class", [flagged objectForKey:@"Sig"], @"Sig", [results objectAtIndex:0], @"Pweep", nil];
			
		}
	}
	
	return nil;
}


+ (NSArray*)searchForPweepsLikeSig:(NSString*)searchSig context:(NSManagedObjectContext*)context
{
	NSFetchRequest *req = [[NSFetchRequest alloc] init];
	[req setEntity:[NSEntityDescription entityForName:@"Pweep" inManagedObjectContext:context]];
	[req setPredicate:[NSPredicate predicateWithFormat:@"Signature CONTAINS[cd] %@", searchSig]];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
										initWithKey:@"Level" ascending:NO];
	[req setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[sortDescriptor release];
	
	
	NSError *fetchError = nil;
	return [context executeFetchRequest:req error:&fetchError];
	
	return [NSArray arrayWithObject:nil];
}

@end
