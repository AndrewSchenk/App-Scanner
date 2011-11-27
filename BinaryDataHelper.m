//
//  DataHelper.m
//  APIScanner
//
//  Created by Andrew Schenk on 9/6/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import "BinaryDataHelper.h"
#import "Constants.h"

@implementation BinaryDataHelper

+ (int)sizeOfSectionForKeyword:(NSString*)keyword inData:(NSData*)data
{
	NSData *keyData = [keyword dataUsingEncoding:NSUTF8StringEncoding];
	
	NSRange sectionRange = [data rangeOfData:keyData
									  options:NSDataSearchBackwards
										range:NSMakeRange(0, [data length])];
	
	NSData *sectionData = [data subdataWithRange:NSMakeRange(sectionRange.location, kSymByteLength+96)];
	
	NSData *sizeData = [sectionData subdataWithRange:NSMakeRange(20+96, 4)];
	NSString *totalSizeStr = [BinaryDataHelper stringWithHexBytesFromData:sizeData];
	BOOL switchTwoBytes = YES;
	if ([[totalSizeStr substringFromIndex:2] isEqualToString:@"0000"]) {
		sizeData = [sectionData subdataWithRange:NSMakeRange(20+96, 2)];
		switchTwoBytes = NO;
	}
	
//	NSLog(@"sizeData before endian switch -> %@", [sizeData description]);
	NSData *stringsSize = [BinaryDataHelper switchDataToLittleEndian:sizeData twoBytes:switchTwoBytes];
	
	NSString *sizeStr = [BinaryDataHelper stringWithHexBytesFromData:stringsSize];
	
	return [BinaryDataHelper hexIntValueForString:sizeStr];
}

+ (int)offsetOfSectionForKeyword:(NSString*)keyword inData:(NSData*)data
{
	NSData *keyData = [keyword dataUsingEncoding:NSUTF8StringEncoding];
	
	NSRange sectionRange = [data rangeOfData:keyData
									 options:NSDataSearchBackwards
									   range:NSMakeRange(0, [data length])];
	
	NSData *sectionData = [data subdataWithRange:NSMakeRange(sectionRange.location, kSymByteLength+96)];
	
	NSData *offsetData = [sectionData subdataWithRange:NSMakeRange(16+96, 4)];
	
	NSString *totalOffsetStr = [BinaryDataHelper stringWithHexBytesFromData:offsetData];
	BOOL switchTwoBytes = YES;
	if ([[totalOffsetStr substringFromIndex:2] isEqualToString:@"0000"]) {
		offsetData = [sectionData subdataWithRange:NSMakeRange(16+96, 2)];
		switchTwoBytes = NO;
	}
	
	NSData *stringsOffset = [BinaryDataHelper switchDataToLittleEndian:offsetData twoBytes:switchTwoBytes];
	
	NSString *offSetStr = [BinaryDataHelper stringWithHexBytesFromData:stringsOffset];
	return [BinaryDataHelper hexIntValueForString:offSetStr];
}

+ (NSString*) stringWithHexBytesFromData:(NSData*)data {
	NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:([data length] * 2)];
	const unsigned char *dataBuffer = [data bytes];
	int i;
	for (i = 0; i < [data length]; ++i) {
		[stringBuffer appendFormat:@"%02X", (unsigned long)dataBuffer[i]];
	}
	return [[stringBuffer copy] autorelease];
}

+ (unsigned int)hexIntValueForString:(NSString*)string
{
	
    NSScanner *scanner;
    unsigned int result;
	
    scanner = [NSScanner scannerWithString: string];
	
    [scanner scanHexInt: &result];
	//NSLog(@"%u", result);
    return result;
}

+ (NSData*)switchDataToLittleEndian:(NSData*)bigData twoBytes:(BOOL)shouldSwapTwo
{
	//NSData *bigEndianOffset = [programData subdataWithRange:NSMakeRange(kOffsetPointer, 2)];
	NSMutableData *switchEndianess = [[[NSMutableData alloc] initWithLength:0] autorelease];
	
	if (shouldSwapTwo) {
		[switchEndianess appendData:[bigData subdataWithRange:NSMakeRange(3, 1)]];
		[switchEndianess appendData:[bigData subdataWithRange:NSMakeRange(2, 1)]];
		[switchEndianess appendData:[bigData subdataWithRange:NSMakeRange(1, 1)]];
		[switchEndianess appendData:[bigData subdataWithRange:NSMakeRange(0, 1)]];
	} else {
		[switchEndianess appendData:[bigData subdataWithRange:NSMakeRange(1, 1)]];
		[switchEndianess appendData:[bigData subdataWithRange:NSMakeRange(0, 1)]];
	}
	
	return switchEndianess;
}

char hexCharToNibble(char nibble)
{
	// 0 - 9
	if (nibble >= '0' && nibble <= '9')
		return (nibble - '0') & 0x0F;
	// A - F
	else if (nibble >= 'A' && nibble <= 'F')
		return (nibble - 'A' + 10) & 0x0F;
	// a - f
	else if (nibble >= 'a' && nibble <= 'f')
		return (nibble - 'a' + 10) & 0x0F;
	// Not a hex digit
	else
		[NSException raise:NSInvalidArgumentException format:@"Character %c not a hex digit.", nibble]; 
	return 0; // keep compiler happy
}

char hexCharsToByte(char highNibble, char lowNibble)
{
	return (hexCharToNibble(highNibble) << 4) | hexCharToNibble(lowNibble); 
}

+ (NSString*)hexToAscii:(NSString*)hexStr
{
	// Get the ASCII data out of the string - hexadecimal numbers are expressed in pure ASCII 
	NSData	*asciiData = [hexStr dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]; 
	const char *chars = (char *)[asciiData bytes]; // chars is NOT NULL- terminated! 
	
	if (([asciiData length] % 2) != 0)
	{
		// There were an odd number of hex characters in the source string.
		return nil;
	}
	
	// Set up data storage for the raw bytes we interpret
	NSMutableData *dataInEncoding = [NSMutableData dataWithLength: [asciiData length] / 2]; 
	char *dataChars = [dataInEncoding mutableBytes];
	
	// Loop over the ASCII numbers
	for (NSUInteger i = 0; i < [asciiData length]; i += 2)
	{
		// Interpret each pair of hexadecimal characters into a byte.
		*dataChars++ = hexCharsToByte(chars[i], chars[i + 1]);
	}
	// Create an NSString from the interpreted bytes, using the passed encoding. 
	// NSString will return nil (or throw an exception) if the bytes we parsed can't be 
	// represented in the given encoding.
	return [[[NSString alloc] initWithData:dataInEncoding encoding:NSUTF8StringEncoding] autorelease]; 
}



@end
