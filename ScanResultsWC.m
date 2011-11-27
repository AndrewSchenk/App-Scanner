//
//  ScanResultsWC.m
//  APIScanner
//
//  Created by Andrew Schenk on 9/7/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import "ScanResultsWC.h"
#import "ServerSyncer.h"
#import "SBJSON.h"
#import "Pweep.h"
#import "Constants.h"

@implementation ScanResultsWC
@synthesize flagged;

-(void)windowDidLoad
{
	
	
	if ([flagged count] < 1) {
		[scroll removeFromSuperview];
		[table removeFromSuperview];
		[checkBtn removeFromSuperview];
		[submitBtn removeFromSuperview];
	}
	
	NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:[flagged count]];
	for(id thing in flagged) {
		NSNumber *boolVal = [NSNumber numberWithBool:NO];
		[arr addObject:boolVal];
	}
	feedback = [[NSMutableArray alloc] initWithArray:arr];
	[feedback retain];
	[arr release];
}

-(void)windowWillClose:(id)sender
{
	//[self release];
}

#pragma mark NSTableView Data Source
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [flagged count];
}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex
{
	Pweep* pweep = [[flagged objectAtIndex:rowIndex] objectForKey:@"Pweep"];
	
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
	if ([aTableColumn.identifier isEqualToString:@"CName"]) {
		NSString *classNme = [[flagged objectAtIndex:rowIndex] objectForKey:@"Class"];
		NSTextFieldCell *cell = [[[NSTextFieldCell alloc] initTextCell:classNme] autorelease];
		return cell;
	}
	
	if ([aTableColumn.identifier isEqualToString:@"SDK"]) {
		NSTextFieldCell *cell = [[[NSTextFieldCell alloc] initTextCell:pweep.SDK_Version] autorelease];
		return cell;
	}
	
	if ([aTableColumn.identifier isEqualToString:@"Appropriate"]) {
		BOOL value = [[feedback objectAtIndex:rowIndex] boolValue];
		return [NSNumber numberWithInteger:(value ? NSOnState : NSOffState)];
	}
	
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (feedback) {
		if ([feedback count] > rowIndex && rowIndex >= 0) {
			NSNumber *boolVal = [feedback objectAtIndex:rowIndex];
			[feedback replaceObjectAtIndex:rowIndex withObject:[NSNumber numberWithBool:![boolVal boolValue]]];
		}
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn
{
	if ([aTableColumn.identifier isEqualToString:@"Appropriate"]) {
		return NO;
	}
	return YES;
}

#pragma mark -
#pragma mark Feedback
-(IBAction)checkAll:(id)sender
{
	if ([[checkBtn title] isEqualToString:@"Check All"]) {
		for(int i=0; i< [feedback count]; i++) {
			[feedback replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:YES]];
		}
		[checkBtn setTitle:@"Uncheck All"];
	} else {
		for(int i=0; i< [feedback count]; i++) {
			[feedback replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:NO]];
		}
		[checkBtn setTitle:@"Check All"];
	}

	[table reloadData];
}
-(IBAction)submitFeedback:(id)sender
{
    // open source version does not include any community feedback features.
}

#pragma mark -
#pragma mark NSURLConnection
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{

	[feedbackConnection release];
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
	NSString *sdata = [[NSString alloc] initWithData:connData encoding:NSUTF8StringEncoding];
	//NSLog(@"sdata -> %@", sdata);
	[sdata release];
	
	[connData release];
	[feedbackConnection release];
	
	ServerSyncer *syncer = [[ServerSyncer alloc] init];
	[syncer startSync];
	[syncer release];
}

-(void)dealloc
{
	[flagged release];
	[feedback release];
	[super dealloc];
}

@end
