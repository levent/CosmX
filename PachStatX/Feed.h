//
//  Feed.h
//  PachStatX
//
//  Created by Levent Ali on 18/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Feed : NSManagedObject

@property (nonatomic, retain) NSString * feed_id;
@property (nonatomic, retain) NSSet *feed_datastreams;
@end

@interface Feed (CoreDataGeneratedAccessors)

- (void)addFeed_datastreamsObject:(NSManagedObject *)value;
- (void)removeFeed_datastreamsObject:(NSManagedObject *)value;
- (void)addFeed_datastreams:(NSSet *)values;
- (void)removeFeed_datastreams:(NSSet *)values;

@end
