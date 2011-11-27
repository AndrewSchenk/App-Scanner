//
//  MainCommand.h
//  App Scanner
//
//  Created by Andrew on 2/1/11.
//  Copyright 2011 Chimp Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MainCommand : NSObject {
	BOOL verbose;
	
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}
@property(nonatomic) BOOL verbose;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

-(id)initWithUpdate:(BOOL)updateOn andVerbose:(BOOL)verboseOn;

-(void)startScanningFile:(NSString*)file;

-(void)startScannerWithURL:(NSURL*)url;
-(void)readHexCStringDataInFromURL:(NSURL*)url;
-(void)processHexMethods:(NSArray*)hmethds;
-(void)stripIVarsAndPathsFromStrings:(NSArray*)strings;

-(void)checkMethodsAgainstDatabase:(NSArray*)methods;
-(void)loadPweepsForSigs:(NSArray*)flagged;

-(void)continueScannerWithContents:(NSString *)contents;
-(void)continueScannerWithNormalStrings:(NSArray *)normalStrings;
-(void)continueScanningWithCleanedMethods:(NSArray *)methods;
-(void)continueScanningWithFlagged:(NSArray *)flagged;
-(void)finishScanByShowingResults:(NSArray *)flaggedPweeps;


@end
