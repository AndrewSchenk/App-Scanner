//
//  MainVC.h
//  APIScanner
//
//  Created by Andrew Schenk on 9/2/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScanResultsWC.h"
#import "DropBox.h"
#import "MAAttachedWindow.h"

@interface MainVC : NSWindowController <NSDrawerDelegate, NSTabViewDelegate, NSTableViewDataSource>{
	//NSWindow *window;
	ScanResultsWC *scanResultsWC;
	
	
	// Binary Scanner
	IBOutlet NSTextField *headerLabel, *progressLabel;
	IBOutlet DropBox *box;
	IBOutlet NSImageView *appIcon, *xrayHud;
	IBOutlet NSProgressIndicator *progressIndicator;
	
	NSTimer *animationTimer;
	NSSound *systemSound;
	BOOL hasPrematurelyFinished;
	
	// Search
	IBOutlet NSSearchField *searchField;
	IBOutlet NSDrawer *drawer;
	IBOutlet NSTableView *table;

	// Missing Signature
	IBOutlet NSView *missingSigVw;
	IBOutlet NSButton *misSigBtn;
	IBOutlet NSTextField *missingSignatureTf;
	MAAttachedWindow *misWindow;
	
@private
	NSTimer *guidelinesTimer;
	int startingIndex;
	BOOL hasStarted;
	IBOutlet NSTextView* guidelinesDisplay;
	NSArray *guidelines;
	NSMutableArray *searchResults;
	
	NSMutableData *connData;
}
//@property (assign) IBOutlet NSWindow *window;

// Missing Signatures
-(IBAction)reportMissingSig:(id)sender;
-(IBAction)submitMissingSig:(id)sender;

// Guidelines
-(void)loadNewMessage;

// Animation
-(void)startIconAnimation;
-(void)renderInverseIcon;

// Searching
-(IBAction)toggleDrawer:(id)sender;
-(IBAction)search:(id)sender;

// Binary Scan
-(IBAction)openFile:(id)sender;
-(void)didReceiveDraggedFiles:(NSArray*)files;
-(void)readInBinaryFromFiles:(NSArray*)files;

-(NSImage*)getImageForFile:(NSString*)filepath;

-(void)startScannerWithURL:(NSURL*)url;

-(void)readHexCStringDataInFromURL:(NSURL*)url;
-(void)processHexMethods:(NSArray*)hmethds;
-(void)stripIVarsAndPathsFromStrings:(NSArray*)strings;

-(void)checkMethodsAgainstDatabase:(NSArray*)methods;

@end
