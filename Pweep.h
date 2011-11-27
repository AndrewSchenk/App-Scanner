//
//  Pweep.h
//  Pweep
//
//  Created by Andrew Schenk on 9/7/10.
//  Copyright 2010 Chimp Studios. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Pweep :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * UpdatedAt;
@property (nonatomic, retain) NSNumber * PweepID;
@property (nonatomic, retain) NSString * SDK_Version;
@property (nonatomic, retain) NSNumber * Level_Weight;
@property (nonatomic, retain) NSNumber * Level;
@property (nonatomic, retain) NSString * Signature;

//-(void)flagAppropriateness:(id)sender;

@end



