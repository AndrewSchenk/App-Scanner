//
//  DropBox.h
//  APIScanner
//
//  Created by Andrew Schenk on 9/13/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DropBox : NSView {

	id delegate;
}
@property(nonatomic, retain) id delegate;
@end
