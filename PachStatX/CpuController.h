//
//  CpuController.h
//  PachStatX
//
//  Created by Levent Ali on 18/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBJson.h"
#include <sys/sysctl.h>
#include <sys/types.h>
#include <mach/mach.h>
#include <mach/processor_info.h>
#include <mach/mach_host.h>


@interface CpuController : NSObject {
    processor_info_array_t cpuInfo, prevCpuInfo;
    mach_msg_type_number_t numCpuInfo, numPrevCpuInfo, sizeRam;
    struct info;
    unsigned numCPUs;
    NSTimer *updateTimer;
    NSLock *CPUUsageLock;
    NSMutableArray *myDatastreams;
    SBJsonWriter *jsonWriter;
    
    NSString *feedId;
    NSString *apiKey;
    NSString *url;
    
    NSURLConnection *connectionCosm;
    
    BOOL paused;
}

-(void)updateCpuInfo:(id)sender;
-(void)pause:(id)sender;
-(void)unpause:(id)sender;

@end
