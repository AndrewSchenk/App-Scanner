//
//  MainCommand.m
//  App Scanner
//
//  Created by Andrew on 2/1/11.
//  Copyright 2011 Chimp Studios. All rights reserved.
//

#import "MainCommand.h"
#import "Pweep.h"
#import "Constants.h"
#import "Helpers.h"
#import "ServerSyncer.h"
#import "APIScannerAppDelegate.h"

@implementation MainCommand
@synthesize verbose;
@synthesize managedObjectModel, managedObjectContext, persistentStoreCoordinator;

-(id)initWithUpdate:(BOOL)updateOn andVerbose:(BOOL)verboseOn
{
	self = [super init];
	if (self != nil) {
		managedObjectModel = [self managedObjectModel];
		managedObjectContext = [self managedObjectContext];
		persistentStoreCoordinator = [self persistentStoreCoordinator];
		
		verbose = verboseOn;
		
		if( updateOn ) {
			if ( verbose ) {
				NSLog(@"updating database, this may take 30-60 seconds...");
			}

			ServerSyncer *syncer = [[ServerSyncer alloc] init];
			syncer.cmdContext = managedObjectContext;
			[syncer startCommandLineSync];
			if (verbose) {
				NSLog(@"database updated...");
			}
			[syncer release];
		}
	}
	return self;
}

#pragma mark CORE DATA
/**
 Returns the support directory for the application, used to store the Core Data
 store file.  This code uses a directory named "Pweep" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */
- (NSString *)applicationSupportDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"App Scanner"];
}
/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel) return managedObjectModel;
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}
/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The directory for the store is created, 
 if necessary.)
 */
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
	
    if (persistentStoreCoordinator) return persistentStoreCoordinator;
	
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        //NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
        return nil;
    }
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if ( ![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
            NSLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
            return nil;
		}
    }
    
	
	
    NSURL *url = [NSURL fileURLWithPath:[applicationSupportDirectory stringByAppendingPathComponent: @"Pweep.sqlite"]];
	if(![fileManager fileExistsAtPath:[applicationSupportDirectory stringByAppendingPathComponent: @"Pweep.sqlite"]]) {
		NSString *localPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"contents/Resources/Pweep.sqlite"];
		if (![fileManager fileExistsAtPath:localPath]) {
			if (verbose) {
				NSLog(@"local database couldn't be set up properly. path incorrect : %@", localPath);
				NSLog(@"trying to locate database again...");
			}
			localPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"../Resources/Pweep.sqlite"];
			if (![fileManager fileExistsAtPath:localPath]) {
				NSLog(@"local database couldn't be set up properly. path incorrect : %@", localPath);	
				NSLog(@"no further attempts will be made.  Please copy the Pweep.sqlite file from \"App Scanner.app/contents/Resources/\" to \"~/Library/Application Support/App Scanner/\"");
			}
		}
		//[[NSBundle mainBundle] pathForResource:@"Pweep" ofType:@"sqlite"];
		NSError *copyErr = nil;
		[fileManager copyItemAtPath:localPath
							 toPath:[applicationSupportDirectory stringByAppendingPathComponent:@"Pweep.sqlite"]
							  error:&copyErr];
		if( copyErr ) {
			NSLog(@"%@", [copyErr localizedDescription]);
		}
	}
	
	
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
												  configuration:nil 
															URL:url 
														options:nil 
														  error:&error]){
        [[NSApplication sharedApplication] presentError:error];
        [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
		NSLog(@"%@", [error localizedDescription]);
        return nil;
    }    
	
    return persistentStoreCoordinator;
}
/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext) return managedObjectContext;
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
		NSLog(@"%@", [error localizedDescription]);
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
	
    return managedObjectContext;
}



-(void)startScanningFile:(NSString*)file
{
	if (!([[file pathExtension] isEqualToString:@"app"] || 
		  [[file pathExtension] isEqualToString:@""])       ) {
		
		NSLog(@"Invalid file.  Only .app files or Unix Executable Files (binaries) may be scanned.");
		return;
	}
	
	NSString *binaryPath = [NSString stringWithString:file];
	if ([[file pathExtension] isEqualToString:@"app"]) {
		NSBundle *appBundle = [NSBundle bundleWithPath:file];
		NSString *binaryPath = [appBundle pathForResource:[[[file lastPathComponent] componentsSeparatedByString:@"."] objectAtIndex:0]
												   ofType:@""];
		NSURL *filePath = [NSURL fileURLWithPath:binaryPath];
		[self startScannerWithURL:filePath];
		//[self startScannerWithURL:[NSURL fileURLWithPath:binaryPath]];
	} else {
		[self startScannerWithURL:[NSURL fileURLWithPath:binaryPath]];
	}
}


#pragma mark -
#pragma mark Main Thread Scanning
-(void)startScannerWithURL:(NSURL*)url
{
	if (verbose) {
		NSLog(@"Analyzing Binary File...");
	}
	[self readHexCStringDataInFromURL:url];
}
-(void)readHexCStringDataInFromURL:(NSURL*)url
{
	NSData *programData = [NSData dataWithContentsOfURL:url];
	//NSLog(@"programData.length -> %i", [programData length]);
	int c_string_size = [BinaryDataHelper sizeOfSectionForKeyword:@"__LINKEDIT" inData:programData];
	int c_string_offset = [BinaryDataHelper offsetOfSectionForKeyword:@"__LINKEDIT" inData:programData];
	//NSLog(@"offset => %i; size => %i", c_string_offset, c_string_size);
	
	NSData *stringsData = [programData subdataWithRange:NSMakeRange(c_string_offset, c_string_size)];
	
	[self continueScannerWithContents:[BinaryDataHelper stringWithHexBytesFromData:stringsData]];
	
}
-(void)continueScannerWithContents:(NSString*)contents
{
	if (verbose) {
		NSLog(@"Pulling Method Signatures Out Of Binary...");
	}
	NSArray *hexMethods = [contents componentsSeparatedByString:@"00"];
	
	[self processHexMethods:hexMethods];
}
-(void)processHexMethods:(NSArray*)hmethds
{	
	NSMutableArray *normalMethods = [[[NSMutableArray alloc] initWithCapacity:[hmethds count]] autorelease];
	
	for(NSString *hexStr in hmethds) {
		NSString *mthd = [BinaryDataHelper hexToAscii:hexStr];
		if (mthd) {
			if ([mthd length] > 1) {
				[normalMethods addObject:mthd];
			}
		}
	}
	
	[self continueScannerWithNormalStrings:normalMethods];
}
-(void)continueScannerWithNormalStrings:(NSArray*)normalStrings
{
	if (verbose) {
		NSLog(@"Cleaning up method signatures...");
	}
	[self stripIVarsAndPathsFromStrings:normalStrings];
}
-(void)stripIVarsAndPathsFromStrings:(NSArray*)strings
{
	NSMutableArray *methods = [[[NSMutableArray alloc] initWithCapacity:[strings count]] autorelease];
	
	for(NSString *str in strings) {
		//NSString *mthd = [BinaryDataHelper hexToAscii:hexStr];
		if ([[str substringToIndex:1] isEqualToString:@"-"] || [[str substringToIndex:1] isEqualToString:@"+"]) {
			[methods addObject:str];
		}
	}
	//return methods;
	[self continueScanningWithCleanedMethods:methods];
}
-(void)continueScanningWithCleanedMethods:(NSArray*)methods
{
	if (verbose) {
		NSLog(@"Searching for private method signature matches...");
	}

	// check everything in methods array versus private API database!
	[self checkMethodsAgainstDatabase:methods];
}
-(void)checkMethodsAgainstDatabase:(NSArray*)methods
{
	NSMutableArray* flagged = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
	
	for(NSString* mthd in methods) {
		
		NSString *stripped = [mthd stringByReplacingOccurrencesOfString:@"[" withString:@""];
		stripped = [stripped stringByReplacingOccurrencesOfString:@"]" withString:@""];
		stripped = [stripped stringByReplacingOccurrencesOfString:@"+" withString:@""];
		stripped = [stripped stringByReplacingOccurrencesOfString:@"-" withString:@""];
		
		NSArray *parts = [stripped componentsSeparatedByString:@" "];
		NSDictionary *mthSigDict = nil;
		if ([parts count] > 1) {
			mthSigDict = [NSDictionary dictionaryWithObjectsAndKeys:[parts objectAtIndex:0], @"Class", [parts objectAtIndex:1], @"Sig", nil];
		} else {
			break;
		}
		
		
		if ([ModelDataHelpers stringIsInDatabase:[mthSigDict objectForKey:@"Sig"] context:managedObjectContext]) {
			[flagged addObject:mthSigDict];
		}
		
	}
	
	[self continueScanningWithFlagged:flagged];
}
-(void)continueScanningWithFlagged:(NSArray*)flagged
{
	if (verbose) {
		NSLog(@"Retrieving Details for Matches...");
	}
	
	[self loadPweepsForSigs:flagged];
}
-(void)loadPweepsForSigs:(NSArray*)flagged
{
	NSMutableArray *flaggedPweeps = [[[NSMutableArray alloc] initWithCapacity:[flagged count]] autorelease];
	
	for(NSDictionary * dict in flagged) {
		[flaggedPweeps addObject:[ModelDataHelpers getPweepObjectForSig:dict context:managedObjectContext]];
		
	}
	[self finishScanByShowingResults:flaggedPweeps];
}

NSInteger likelihoodSorter(id g1, id g2, void *context)
{
    Pweep *first = ((Pweep*)[g1 objectForKey:@"Pweep"]);
	Pweep *second = ((Pweep*)[g2 objectForKey:@"Pweep"]);
	
    float v1 = [first.Level floatValue];
    float v2 = [second.Level floatValue];
    if (v1 > v2)
        return NSOrderedAscending;
    else if (v1 < v2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

-(void)finishScanByShowingResults:(NSArray*)flaggedPweeps
{
	if (verbose) {
		NSLog(@"Scan Complete...");
	}
	NSArray *sorted = [flaggedPweeps sortedArrayUsingFunction:likelihoodSorter context:NULL];
	
	NSMutableString *outputStr = [[NSMutableString alloc] initWithCapacity:0];
	for( int i=0; i<[sorted count]; i++) {
		Pweep* pweep = [[sorted objectAtIndex:i] objectForKey:@"Pweep"];
		[outputStr appendFormat:@"Likelihood: %i (pc)\tSignature: %@\tClass: %@", [pweep.Level intValue], pweep.Signature, [[sorted objectAtIndex:i] objectForKey:@"Class"] ];
		NSLog(@"%@", outputStr);
		[outputStr setString:@""];
	}
	if ([sorted count] < 1) {
		NSLog(@"No offending methods were found.  Please note that your app MAY STILL BE REJECTED for private API usage.  You can adjust the filter rate with the -l flag.");
	}
	
	[outputStr release];
	
	//scanResultsWC = [[ScanResultsWC alloc] initWithWindowNibName:@"ScanResultsWC"];
	//scanResultsWC.flagged = [flaggedPweeps sortedArrayUsingFunction:likelihoodSort context:NULL];
	//[scanResultsWC showWindow:scanResultsWC.window];
}

-(void)dealloc
{
	[managedObjectContext release];
    [persistentStoreCoordinator release];
    [managedObjectModel release];
	[super dealloc];
}

@end
