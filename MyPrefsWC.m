//
//  MyPrefsWC.m
//  APIScanner
//
//  Created by Andrew Schenk on 9/7/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import "MyPrefsWC.h"
#import "Constants.h"

@implementation MyPrefsWC

- (void)setupToolbar
{
	[self addView:generalPrefsView label:@"General"];
	
	// GENERAL PREFS
	// Setup Filter Slider & Label
	[percentageSlider setContinuous:YES];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefFilterSet]) {
		[percentageSlider setIntValue:[[NSUserDefaults standardUserDefaults] integerForKey:kPrefFilter]];
	}
	[self setPercentage:nil];
	
}

#pragma mark -
#pragma mark General Prefs
-(IBAction)setPercentage:(id)sender
{
	int percentage = [percentageSlider integerValue];
	[[NSUserDefaults standardUserDefaults] setInteger:percentage forKey:kPrefFilter];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPrefFilterSet];
	NSString *message;
	if (percentage > 0 && percentage < 100) {
		message = [NSString stringWithFormat:@"Filter results that have %i%@ likelihood of being Private APIs", percentage, @"%"];
	} else if (percentage == 0) {
		message = @"Show all results";
	} else if (percentage == 100) {
		message = @"Show me only confirmed Private APIs";
	}
	[percentageLbl setStringValue:message];
	
}


@end
