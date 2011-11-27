//
//  main.m
//  APIScanner
//
//  Created by Andrew Schenk on 9/2/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MainCommand.h"
#import "Constants.h"


int main(int argc, char *argv[])
{
	NSAutoreleasePool *myPool = [[NSAutoreleasePool alloc] init];
	
	NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
	NSString *path	= [args stringForKey:@"p"];
	BOOL verbose	= [args boolForKey:@"v"];
	BOOL update		= [args boolForKey:@"u"];
	if([args integerForKey:@"l"]) {
		int level		= [args integerForKey:@"l"];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPrefFilterSet];
		[[NSUserDefaults standardUserDefaults] setInteger:level forKey:kPrefFilter];
	}

	
	if (verbose) {
		NSLog(@"path = %@", path);
		if([args integerForKey:@"l"]) {
			NSLog(@"filter level = %i (pc)", [args integerForKey:@"l"]);
		} else {
			NSLog(@"filter level not set, using default");
		}
		NSLog(@"verbose is ON");
	}

	
	if (path) {
		MainCommand *mc = [[MainCommand alloc] initWithUpdate:update andVerbose:verbose];
		if (verbose) {
			NSLog(@"starting scanner...");
		}
		[mc startScanningFile:path];
		[mc release];
		[myPool release];
		return 0;
	}
	[myPool release];
    return NSApplicationMain(argc,  (const char **) argv);
}


