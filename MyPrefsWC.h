//
//  MyPrefsWC.h
//  APIScanner
//
//  Created by Andrew Schenk on 9/7/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "DBPrefsWindowController.h"

@interface MyPrefsWC : DBPrefsWindowController {
	IBOutlet NSView *generalPrefsView;
	IBOutlet NSView *otherPrefsView;
	
	// General Prefs
	IBOutlet NSSlider *percentageSlider;
	IBOutlet NSTextField *percentageLbl;
	
	
	// Purchase Prefs
	IBOutlet WebView *macAppStore;
}

// General Prefs
-(IBAction)setPercentage:(id)sender;

@end
