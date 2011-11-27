//
//  APIScannerAppDelegate.m
//  APIScanner
//
//  Created by Andrew Schenk on 9/2/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import "APIScannerAppDelegate.h"
#import "ServerSyncer.h"
#import "Constants.h"


@implementation APIScannerAppDelegate
@synthesize mainVC;
@synthesize managedObjectModel, managedObjectContext, persistentStoreCoordinator;
@synthesize threadedContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	
    NSAlert *eulaAlert = [NSAlert alertWithMessageText:@"I acknowledge that this tool is made by a 3rd party developer and is in no way endorsed by Apple Inc.  Even if my app passes the tests within App Scanner, it could still be rejected by Apple reviewers for any reason including the usage of private APIs.  I also acknowledge that the scanning process within App Scanner is not the same process that Apple uses and therefore is not complete." defaultButton:@"Decline" alternateButton:@"Accept" otherButton:nil informativeTextWithFormat:@""];
    NSInteger value = [eulaAlert runModal];
    if (value == NSAlertDefaultReturn) {
        [[NSApplication sharedApplication] terminate:nil];
    } else {
        [self showMainView];
        managedObjectModel = [self managedObjectModel];
        managedObjectContext = [self managedObjectContext];
        persistentStoreCoordinator = [self persistentStoreCoordinator];
        
        threadedContext = [self managedThreadedContext];
        
        int launchCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"launch.count"];
        if (launchCount == 0) {
            //[self triggerUpdateBubble:nil];
        }
        launchCount++;
        [[NSUserDefaults standardUserDefaults] setInteger:launchCount forKey:@"launch.count"];
    }
}

-(IBAction)triggerUpdateBubble:(id)sender
{
    /*
	// Attach/detach window
    if (!updateWindow) {
		
        NSPoint buttonPoint = NSMakePoint([[mainVC window] frame].size.width/2,
                                          [[mainVC window] frame].size.height);
        updateWindow = [[MAAttachedWindow alloc] initWithView:updateBubble 
										   attachedToPoint:buttonPoint 
												  inWindow:[mainVC window] 
													onSide:MAPositionTop 
												atDistance:5];
        [updateWindow setBorderColor:[NSColor grayColor]];
        [updateWindow setBackgroundColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.99]];
        [updateWindow setViewMargin:10];
        [updateWindow setBorderWidth:2];
        [updateWindow setCornerRadius:5];
        [updateWindow setHasArrow:YES];
        [updateWindow setDrawsRoundCornerBesideArrow:NO];
        [updateWindow setArrowBaseWidth:25];
        [updateWindow setArrowHeight:20];
        
        [[mainVC window] addChildWindow:updateWindow ordered:NSWindowAbove];
    } else {
        [[mainVC window] removeChildWindow:updateWindow];
        [updateWindow orderOut:self];
        [updateWindow release];
        updateWindow = nil;
    }
     */
}

-(IBAction)startUpdatingDatabase:(id)sender
{
	//ServerSyncer *syncer = [[ServerSyncer alloc] init];
	//[syncer startSync];
	//[syncer release];
}

- (IBAction)openFile:(id)sender
{
	if (mainVC) {
		[mainVC openFile:sender];
	}
}

-(void)showMainView
{
	if (!mainVC) {
		mainVC = [[MainVC alloc] initWithWindowNibName:@"MainVC"];
		[mainVC window];
		//[mainVC.window makeKeyAndOrderFront:NSApp];
		//[mainVC.window makeMainWindow];
		//[[[NSApplication sharedApplication] mainWindow] makeKeyAndOrderFront:self];
		[mainVC retain];
		return;
	}
	[mainVC window];
}

- (IBAction)openPreferencesWindow:(id)sender
{
	[[MyPrefsWC sharedPrefsWindowController] showWindow:nil];
}

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
       // NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
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
		NSString *localPath = [[NSBundle mainBundle] pathForResource:@"Pweep" ofType:@"sqlite"];
		[fileManager copyItemAtPath:localPath
							 toPath:[applicationSupportDirectory stringByAppendingPathComponent:@"Pweep.sqlite"]
							  error:nil];
	}
	
	
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
												  configuration:nil 
															URL:url 
														options:nil 
														  error:&error]){
        [[NSApplication sharedApplication] presentError:error];
        [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
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
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
	
    return managedObjectContext;
}


- (NSManagedObjectContext *) managedThreadedContext {
	
    if (threadedContext) return threadedContext;
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    threadedContext = [[NSManagedObjectContext alloc] init];
    [threadedContext setPersistentStoreCoordinator: coordinator];
	
    return threadedContext;
}


/**
 Returns the NSUndoManager for the application.  In this case, the manager
 returned is that of the managed object context for the application.
 */

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	
    if (!managedObjectContext) return NSTerminateNow;
	
    if (![managedObjectContext commitEditing]) {
       // NSLog(@"%@:%s unable to commit editing to terminate", [self class], _cmd);
        return NSTerminateCancel;
    }
	
    
    if (![managedObjectContext hasChanges]) return NSTerminateNow;
    
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        
        // This error handling simply presents error information in a panel with an 
        // "Ok" button, which does not include any attempt at error recovery (meaning, 
        // attempting to fix the error.)  As a result, this implementation will 
        // present the information to the user and then follow up with a panel asking 
        // if the user wishes to "Quit Anyway", without saving the changes.
        
        // Typically, this process should be altered to include application-specific 
        // recovery steps.  
        
        BOOL result = [sender presentError:error];
        if (result) return NSTerminateCancel;
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
        
    }
	
    return NSTerminateNow;
}


/**
 Implementation of dealloc, to release the retained variables.
 */

- (void)dealloc {
	[mainVC release];
    [managedObjectContext release];
    [persistentStoreCoordinator release];
    [managedObjectModel release];
	
    [super dealloc];
}

@end
