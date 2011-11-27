//
//  ScanResultsWC.h
//  APIScanner
//
//  Created by Andrew Schenk on 9/7/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface ScanResultsWC : NSWindowController <NSTableViewDelegate, NSTableViewDataSource, NSWindowDelegate> {

	IBOutlet NSTableView *table;
	IBOutlet NSScrollView *scroll;
	
	NSArray *flagged;
	NSMutableArray *feedback;
	
	IBOutlet NSButton *checkBtn, *submitBtn;
	
	IBOutlet NSView *resultsView, *vdata;
	
	// Purchase Prefs
	IBOutlet WebView *paypalBtn;
	IBOutlet WebView *googleBtn;
	
	IBOutlet NSTextField *entree;
	IBOutlet NSImageView *entreeResult;
	
@private
	NSURLConnection *feedbackConnection;
	NSMutableData *connData;
}
@property(nonatomic, retain) NSArray *flagged;

-(IBAction)checkAll:(id)sender;
-(IBAction)submitFeedback:(id)sender;

@end
