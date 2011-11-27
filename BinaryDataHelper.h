//
//  DataHelper.h
//  APIScanner
//
//  Created by Andrew Schenk on 9/6/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BinaryDataHelper : NSObject {

}

+ (int)sizeOfSectionForKeyword:(NSString*)keyword inData:(NSData*)data;
+ (int)offsetOfSectionForKeyword:(NSString*)keyword inData:(NSData*)data;

+ (NSString*)stringWithHexBytesFromData:(NSData*)data;
+ (unsigned int)hexIntValueForString:(NSString*)string;
+ (NSData*)switchDataToLittleEndian:(NSData*)bigData twoBytes:(BOOL)shouldSwapTwo;
+ (NSString*)hexToAscii:(NSString*)hexStr;
@end
