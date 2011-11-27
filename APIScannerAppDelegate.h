//
//  APIScannerAppDelegate.h
//  APIScanner
//
//  Created by Andrew Schenk on 9/2/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MainVC.h"
#import "MyPrefsWC.h"

@interface APIScannerAppDelegate : NSObject <NSApplicationDelegate> {
    
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
	NSManagedObjectContext *threadedContext;
	
	MainVC *mainVC;

	MAAttachedWindow *updateWindow;
	IBOutlet NSView *updateBubble;
	IBOutlet NSMenuItem *appScannerMi;
}

@property(nonatomic, retain) MainVC *mainVC;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectContext *threadedContext;

-(IBAction)triggerUpdateBubble:(id)sender;
-(void)showMainView;

-(IBAction)startUpdatingDatabase:(id)sender;
- (IBAction)openPreferencesWindow:(id)sender;
- (IBAction)openFile:(id)sender;

- (NSManagedObjectContext *) managedThreadedContext;

@end
