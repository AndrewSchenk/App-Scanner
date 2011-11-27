//
//  MainVC.m
//  APIScanner
//
//  Created by Andrew Schenk on 9/2/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import "MainVC.h"
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <AppKit/AppKit.h>
#import "Constants.h"
#import "Helpers.h"
#import "APIScannerAppDelegate.h"
#import "Pweep.h"

#define kMinorIncrement 3.3
#define kMajorIncrement 45

#define kTimerInterval 8

@implementation MainVC
//@synthesize window;

-(void)awakeFromNib
{
	[box setDelegate:self];
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"appstore_review_guidelines" ofType:@"txt"];
	NSString *guides = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
	guidelines = [guides componentsSeparatedByString:@"\n"];
	[guidelines retain];
	guidelinesTimer = [NSTimer scheduledTimerWithTimeInterval:kTimerInterval
													   target:self
													 selector:@selector(loadNewMessage)
													 userInfo:nil
													  repeats:YES];
	[guidelinesTimer retain];
	[guidelinesTimer fire];
	[guidelinesDisplay setFont:[NSFont systemFontOfSize:12]];
	//[guidelinesDisplay setAlignment:NSCenterTextAlignment];
	[guidelinesDisplay setAlignment:NSCenterTextAlignment];
	//[self loadNewMessage];
}
-(void)windowDidLoad
{
	[box registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	
}


-(IBAction)reportMissingSig:(id)sender
{
	// Attach/detach window
    if (!misWindow) {
		
        NSPoint buttonPoint = NSMakePoint(NSMidX([misSigBtn frame]),
                                          NSMidY([misSigBtn frame]));
        misWindow = [[MAAttachedWindow alloc] initWithView:missingSigVw 
										   attachedToPoint:buttonPoint 
												  inWindow:[misSigBtn window] 
													onSide:MAPositionAutomatic 
												atDistance:[misSigBtn frame].size.height/2];
        [misWindow setBorderColor:[NSColor grayColor]];
        [misWindow setBackgroundColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.99]];
        [misWindow setViewMargin:10];
        [misWindow setBorderWidth:2];
        [misWindow setCornerRadius:5];
        [misWindow setHasArrow:YES];
        [misWindow setDrawsRoundCornerBesideArrow:NO];
        [misWindow setArrowBaseWidth:25];
        [misWindow setArrowHeight:20];
        
        [[misSigBtn window] addChildWindow:misWindow ordered:NSWindowAbove];
    } else {
        [[misSigBtn window] removeChildWindow:misWindow];
        [misWindow orderOut:self];
        [misWindow release];
        misWindow = nil;
    }
}

-(IBAction)submitMissingSig:(id)sender
{
	// open source version does not include any community feedback features.
}


#pragma mark -
#pragma mark NSURLConnection
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSAlert *err = [NSAlert alertWithError:error];
	[err runModal];
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
	NSString *response = [[NSString alloc] initWithData:connData encoding:NSUTF8StringEncoding];
	
	NSAlert *rsp = [NSAlert alertWithMessageText:response
								   defaultButton:@"Okay"
								 alternateButton:nil
									 otherButton:nil
					   informativeTextWithFormat:@""];
	[rsp runModal];
	
	[response release];
	
	[connData release];
}


#pragma mark -
#pragma mark Guidelines
-(void)loadNewMessage
{
	if (!hasStarted) {
		hasStarted = YES;
		startingIndex = arc4random()%[guidelines count];
	}
	NSString *newStr = [NSString stringWithFormat:@"\"%@\"", [guidelines objectAtIndex:startingIndex]];
	//[guidelinesDisplay setString:newStr];
	//[guidelinesDisplay setAlignment:NSCenterTextAlignment range:NSMakeRange(0,[newStr length])];
	
	
	
	NSData *data = [newStr dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:@"http://developer.apple.com/appstore/guidelines.html"];
    NSAttributedString *attrString = [[NSAttributedString alloc]
									  initWithHTML: data baseURL: url documentAttributes: (NSDictionary **) NULL];
    [[guidelinesDisplay textStorage] setAttributedString: attrString];
    [attrString release];
	
	[guidelinesDisplay setAlignment:NSCenterTextAlignment];
	
	startingIndex++;
	if (startingIndex > [guidelines count] - 1) {
		startingIndex = 0;
	}
}

#pragma mark -
#pragma mark Dragging
-(void)didReceiveDraggedFiles:(NSArray*)files
{
	[self readInBinaryFromFiles:files];
}

#pragma mark -
#pragma mark Search
-(IBAction)toggleDrawer:(id)sender
{
	if([drawer state] == NSDrawerOpenState && [[searchField stringValue] length] <= 0) {
		[drawer close];
	} else {
		[drawer open];
	}

}
-(IBAction)search:(id)sender
{
	[self toggleDrawer:nil];
	APIScannerAppDelegate *delegate = (APIScannerAppDelegate*)[[NSApplication sharedApplication] delegate]; 
	
	NSString *searchString = [sender stringValue];
	NSArray *results = [ModelDataHelpers searchForPweepsLikeSig:searchString context:delegate.managedObjectContext];
	if (searchResults) {
		[searchResults release];
		searchResults = nil;
	}
	searchResults = [NSMutableArray arrayWithArray:results];
	[searchResults retain];
	[table reloadData];
}

#pragma mark NSTableView Data Source
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [searchResults count];
}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex
{
	Pweep* pweep = [searchResults objectAtIndex:rowIndex];
	
	if ([aTableColumn.identifier isEqualToString:@"Signature"]) {
		NSTextFieldCell *cell = [[[NSTextFieldCell alloc] initTextCell:pweep.Signature] autorelease];
		return cell;
	}
	
	if ([aTableColumn.identifier isEqualToString:@"Likelihood"]) {
		int percentage = [pweep.Level intValue];
		NSTextFieldCell *cell = [[[NSTextFieldCell alloc] initTextCell:[NSString stringWithFormat:@"%i%@", percentage, @"%"]] autorelease];
		if (percentage > 70) {
			[cell setTextColor:[NSColor greenColor]];
		} else if (percentage >= 50 && percentage <= 70) {
			[cell setTextColor:[NSColor brownColor]];
		} else if (percentage >= 25 && percentage < 50) {
			[cell setTextColor:[NSColor orangeColor]];
		} else {
			[cell setTextColor:[NSColor redColor]];
		}
		[cell setAlignment:NSCenterTextAlignment];
		return cell;
	}
	
	return nil;
}

#pragma mark -
#pragma mark Binary Scan
-(IBAction)openFile:(id)sender
{
	// Create the File Open Dialog class.
	NSOpenPanel* openDlg = [NSOpenPanel openPanel];
	
	// Enable the selection of files in the dialog.
	[openDlg setCanChooseFiles:YES];
	
	// Display the dialog.  If the OK button was pressed,
	// process the files.
	if ( [openDlg runModalForDirectory:nil file:nil] == NSOKButton )
	{
		// Get an array containing the full filenames of all
		// files and directories selected.
		NSArray* files = [openDlg filenames];
		[self readInBinaryFromFiles:files];
	}
}

// Open either a binary or a .app file
-(void)readInBinaryFromFiles:(NSArray*)files
{
	NSString * file = [files objectAtIndex:0];
	if (!([[file pathExtension] isEqualToString:@"app"] || 
		[[file pathExtension] isEqualToString:@""])       ) {
		
		NSAlert *err = [NSAlert alertWithMessageText:@"Invalid file.  Only .app files or Unix Executable Files (binaries) may be scanned."
									   defaultButton:@"Okay"
									 alternateButton:nil
										 otherButton:nil
						   informativeTextWithFormat:@""];
		
		[err runModal];
		
		return;
	}
	
	[appIcon setImage:[self getImageForFile:file]];
	[self startIconAnimation];
	
	NSString *binaryPath = [NSString stringWithString:file];
	if ([[file pathExtension] isEqualToString:@"app"]) {
		NSBundle *appBundle = [NSBundle bundleWithPath:file];
		NSString *binaryPath = [appBundle pathForResource:[[[file lastPathComponent] componentsSeparatedByString:@"."] objectAtIndex:0]
												   ofType:@""];
		NSURL *filePath = [NSURL fileURLWithPath:binaryPath];
		[self startScannerWithURL:filePath];
		return;
	}
	[self startScannerWithURL:[NSURL fileURLWithPath:binaryPath]];
}

#pragma mark -
#pragma mark Icon Drop Animation
-(void)startIconAnimation
{
	hasPrematurelyFinished = NO;
	systemSound = [NSSound soundNamed:@"zap"];
	[systemSound setLoops:YES];
	[systemSound setVolume:0.2];
	[systemSound retain];
	
	NSRect finalRect = appIcon.frame;
	[appIcon setFrame:NSMakeRect(appIcon.frame.origin.x,
								 self.window.frame.size.height + appIcon.frame.size.height,
								 appIcon.frame.size.width,
								 appIcon.frame.size.height)];
	 
	NSViewAnimation *theAnim;
	
	NSMutableDictionary* firstViewDict;
	 
	{
        // Create the attributes dictionary for the first view.
        firstViewDict = [NSMutableDictionary dictionaryWithCapacity:3];
		
        // Specify which view to modify.
        [firstViewDict setObject:appIcon forKey:NSViewAnimationTargetKey];
		
        // Specify the starting position of the view.
        [firstViewDict setObject:[NSValue valueWithRect:[appIcon frame]]
						  forKey:NSViewAnimationStartFrameKey];
		
        // Change the ending position of the view.
        [firstViewDict setObject:[NSValue valueWithRect:finalRect]
						  forKey:NSViewAnimationEndFrameKey];
    }
	
	[systemSound play];
	
	theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray
															   arrayWithObjects:firstViewDict, nil]];
	
	double duration = 0.9;
	[theAnim setDuration:duration];
    [theAnim setAnimationCurve:NSAnimationEaseIn];
	
    // Run the animation.
    [theAnim startAnimation];
	
    // The animation has finished, so go ahead and release it.
    [theAnim release];
	
	NSTimer *waitTimer = [NSTimer scheduledTimerWithTimeInterval:duration
														  target:self
														selector:@selector(renderInverseIcon) 
														userInfo:nil
														 repeats:NO];
	waitTimer = nil;
}

-(void)renderInverseIcon
{
	if (!hasPrematurelyFinished) {
		//NSLog(@"renderInverseIcon...");
		CIImage* ciImage = [[CIImage alloc] initWithData:[[appIcon image] TIFFRepresentation]];
		if ([[appIcon image] isFlipped])
		{
			CGRect cgRect    = [ciImage extent];
			CGAffineTransform transform;
			transform = CGAffineTransformMakeTranslation(0.0,cgRect.size.height);
			transform = CGAffineTransformScale(transform, 1.0, -1.0);
			ciImage   = [ciImage imageByApplyingTransform:transform];
		}
		CIFilter* filter = [CIFilter filterWithName:@"CIColorInvert"];
		[filter setDefaults];
		[filter setValue:ciImage forKey:@"inputImage"];
		CIImage* output = [filter valueForKey:@"outputImage"];
		NSBitmapImageRep* rep =
		[[[NSBitmapImageRep alloc] initWithCIImage:output] autorelease];
		CGImageRef outputCG = rep.CGImage;
		NSImage* inverted = [[NSImage alloc] initWithCGImage:outputCG size:NSZeroSize];
		appIcon.image = inverted;
		
		[appIcon retain];
		[appIcon removeFromSuperview];
		[self.window.contentView addSubview:appIcon positioned:NSWindowAbove relativeTo:nil]; 
		[appIcon release];
		// start zapping timer
		animationTimer = [NSTimer scheduledTimerWithTimeInterval:2
														  target:self
														selector:@selector(zap)
														userInfo:nil
														 repeats:YES];
		[animationTimer retain];
		[animationTimer fire];
	}
}

-(void)zap
{
	NSViewAnimation *theAnimfirst;
	
	NSMutableDictionary* firstanimViewDict;
	
	{
        // Create the attributes dictionary for the first view.
        firstanimViewDict = [NSMutableDictionary dictionaryWithCapacity:2];
		
        // Specify which view to modify.
        [firstanimViewDict setObject:appIcon forKey:NSViewAnimationTargetKey];
		
        // Specify the starting position of the view.
        [firstanimViewDict setObject:NSViewAnimationFadeInEffect
						  forKey:NSViewAnimationEffectKey];
    }
	
	theAnimfirst = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray
															   arrayWithObjects:firstanimViewDict, nil]];
	
	double duration = 0.01;
	[theAnimfirst setDuration:duration];
    [theAnimfirst setAnimationCurve:NSAnimationEaseIn];
	
    // Run the animation.
    [theAnimfirst startAnimation];
	
    // The animation has finished, so go ahead and release it.
    [theAnimfirst release];
	//
	
	NSViewAnimation *theAnim;
	
	NSMutableDictionary* firstViewDict;
	
	{
        // Create the attributes dictionary for the first view.
        firstViewDict = [NSMutableDictionary dictionaryWithCapacity:2];
		
        // Specify which view to modify.
        [firstViewDict setObject:appIcon forKey:NSViewAnimationTargetKey];
		
        // Specify the starting position of the view.
        [firstViewDict setObject:NSViewAnimationFadeOutEffect
						  forKey:NSViewAnimationEffectKey];
    }
	
	theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray
															   arrayWithObjects:firstViewDict, nil]];
	
	duration = 0.9;
	[theAnim setDuration:duration];
    [theAnim setAnimationCurve:NSAnimationEaseIn];
	
    // Run the animation.
    [theAnim startAnimation];
	
    // The animation has finished, so go ahead and release it.
    [theAnim release];
	
	
}

// return the app icon or a default image
-(NSImage*)getImageForFile:(NSString*)filepath
{
	NSWorkspace *workSpace = [[[NSWorkspace alloc] init] autorelease];
	
	if ([[filepath pathExtension] isEqualToString:@"app"]) {
		NSBundle *appBundle = [NSBundle bundleWithPath:filepath];
		NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[appBundle pathForResource:@"Info" ofType:@"plist"]];
		if (info) {
			//NSLog(@"info -> %@", [info description]);
			NSString *iconName = [info objectForKey:@"CFBundleIconFile"];
			if (iconName) {
				return [[[NSImage alloc] initByReferencingFile:[filepath stringByAppendingPathComponent:iconName]] autorelease];
			}
		}
	}
	
	return [workSpace iconForFile:filepath];
}

#pragma mark -
#pragma mark Main Thread Scanning
-(void)startScannerWithURL:(NSURL*)url
{
	//NSLog(@"url -> %@", [url description]);
	NSString *progressText = [NSString stringWithFormat:@"Scanning \"%@\"", [url lastPathComponent]];
	[headerLabel setStringValue:progressText];
	[progressLabel setStringValue:@"Analyzing Binary File..."];
	[progressIndicator incrementBy:10];
	[NSThread detachNewThreadSelector:@selector(readHexCStringDataInFromURL:)
							 toTarget:self
						   withObject:url];
	
	//NSString *contents = [self readHexCStringDataInFromURL:url];
	
	//NSLog(@"%@", contents);
	
	
	//[scanResultsWC release];	
}
-(void)continueScannerWithContents:(NSString*)contents
{
	[progressLabel setStringValue:@"Pulling Method Signatures Out Of Binary..."];
	[progressIndicator incrementBy:kMinorIncrement];
	NSArray *hexMethods = [contents componentsSeparatedByString:@"00"];
	
	[NSThread detachNewThreadSelector:@selector(processHexMethods:)
							 toTarget:self
						   withObject:hexMethods];	
}

-(void)continueScannerWithNormalStrings:(NSArray*)normalStrings
{
	[progressLabel setStringValue:@"Cleaning up method signatures..."];
	[progressIndicator incrementBy:kMinorIncrement];
	
	[NSThread detachNewThreadSelector:@selector(stripIVarsAndPathsFromStrings:)
							 toTarget:self
						   withObject:normalStrings];
}
-(void)continueScanningWithCleanedMethods:(NSArray*)methods
{
	[progressLabel setStringValue:@"Searching for private method signature matches..."];
	//[progressIndicator incrementBy:10];
	
	// check everything in methods array versus private API database!
	[NSThread detachNewThreadSelector:@selector(checkMethodsAgainstDatabase:)
							 toTarget:self
						   withObject:methods];
}
-(void)continueScanningWithFlagged:(NSArray*)flagged
{
	[progressLabel setStringValue:@"Retrieving Details for Matches..."];
	//[progressIndicator incrementBy:10];
	
	[NSThread detachNewThreadSelector:@selector(loadPweepsForSigs:)
							 toTarget:self
						   withObject:flagged];
}

NSInteger likelihoodSort(id g1, id g2, void *context)
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
	[headerLabel setStringValue:@"Scan Complete..."];
	[progressLabel setStringValue:@""];
	[progressIndicator incrementBy:kMinorIncrement];
	
	
	[progressIndicator incrementBy:-100];
	hasPrematurelyFinished = YES;
	if (animationTimer) {
		[animationTimer invalidate];
		[animationTimer release];
		animationTimer = nil;
	}
	
	if (systemSound) {
		[systemSound stop];
		[systemSound release];
		systemSound = nil;
	}
	
	scanResultsWC = [[ScanResultsWC alloc] initWithWindowNibName:@"ScanResultsWC"];
	
	scanResultsWC.flagged = [flaggedPweeps sortedArrayUsingFunction:likelihoodSort context:NULL];
	
	[scanResultsWC showWindow:scanResultsWC.window];
	
	
}

#pragma mark -
#pragma mark Secondary Thread Scanning
-(void)readHexCStringDataInFromURL:(NSURL*)url
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSData *programData = [NSData dataWithContentsOfURL:url];
	//NSLog(@"programData.length -> %i", [programData length]);
	int c_string_size = [BinaryDataHelper sizeOfSectionForKeyword:@"__LINKEDIT" inData:programData];
	int c_string_offset = [BinaryDataHelper offsetOfSectionForKeyword:@"__LINKEDIT" inData:programData];
	//NSLog(@"offset => %i; size => %i", c_string_offset, c_string_size);
	
	NSData *stringsData = [programData subdataWithRange:NSMakeRange(c_string_offset, c_string_size)];

	[self performSelectorOnMainThread:@selector(continueScannerWithContents:)
						   withObject:[BinaryDataHelper stringWithHexBytesFromData:stringsData]
						waitUntilDone:NO];
	[pool release];
}
-(void)processHexMethods:(NSArray*)hmethds
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray *normalMethods = [[[NSMutableArray alloc] initWithCapacity:[hmethds count]] autorelease];
	
	for(NSString *hexStr in hmethds) {
		NSString *mthd = [BinaryDataHelper hexToAscii:hexStr];
		if (mthd) {
			if ([mthd length] > 1) {
				[normalMethods addObject:mthd];
			}
		}
	}
	
	[self performSelectorOnMainThread:@selector(continueScannerWithNormalStrings:)
						   withObject:normalMethods
						waitUntilDone:NO];
	[pool release];
}
-(void)stripIVarsAndPathsFromStrings:(NSArray*)strings
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray *methods = [[[NSMutableArray alloc] initWithCapacity:[strings count]] autorelease];
	
	for(NSString *str in strings) {
		//NSString *mthd = [BinaryDataHelper hexToAscii:hexStr];
		if ([[str substringToIndex:1] isEqualToString:@"-"] || [[str substringToIndex:1] isEqualToString:@"+"]) {
			[methods addObject:str];
		}
	}
	//return methods;
	[self performSelectorOnMainThread:@selector(continueScanningWithCleanedMethods:)
						   withObject:methods
						waitUntilDone:NO];
	[pool release];
}
-(void)checkMethodsAgainstDatabase:(NSArray*)methods
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray* flagged = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
	
	APIScannerAppDelegate *delegate = (APIScannerAppDelegate*)[[NSApplication sharedApplication] delegate]; 
	double methodsCount = (double)[methods count];
	double incrementBy = kMajorIncrement/methodsCount;
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

		
		if ([ModelDataHelpers stringIsInDatabase:[mthSigDict objectForKey:@"Sig"] context:delegate.threadedContext]) {
			[flagged addObject:mthSigDict];
		}
		
		// Update the progress Bar
		[self performSelectorOnMainThread:@selector(updateProgressBarBy:)
							   withObject:[NSNumber numberWithDouble:incrementBy]
							waitUntilDone:NO];
		
	}
	[self performSelectorOnMainThread:@selector(continueScanningWithFlagged:)
						   withObject:flagged
						waitUntilDone:NO];
	[pool release];
}
-(void)loadPweepsForSigs:(NSArray*)flagged
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	APIScannerAppDelegate *delegate = (APIScannerAppDelegate*)[[NSApplication sharedApplication] delegate]; 
	NSMutableArray *flaggedPweeps = [[[NSMutableArray alloc] initWithCapacity:[flagged count]] autorelease];
	
	double methodsCount = (double)[flagged count];
	double incrementBy = kMajorIncrement/methodsCount;
	
	for(NSDictionary * dict in flagged) {
		[flaggedPweeps addObject:[ModelDataHelpers getPweepObjectForSig:dict context:delegate.threadedContext]];
		
		[self performSelectorOnMainThread:@selector(updateProgressBarBy:)
							   withObject:[NSNumber numberWithDouble:incrementBy]
							waitUntilDone:NO];
	}
	[self performSelectorOnMainThread:@selector(finishScanByShowingResults:)
						   withObject:flaggedPweeps
						waitUntilDone:NO];
	
	[pool release];
}


-(void)updateProgressBarBy:(NSNumber*)increment
{
	[progressIndicator incrementBy:[increment doubleValue]];
}

#pragma mark -
#pragma mark Memory Management
-(void)dealloc
{
	if (systemSound) {
		[systemSound stop];
		[systemSound release];
		systemSound = nil;
	}
	if (animationTimer) {
		[animationTimer invalidate];
		[animationTimer release];
		animationTimer = nil;
	}
	[guidelinesTimer invalidate];
	[guidelinesTimer release];
	[guidelines release];
	[super dealloc];
}

@end
