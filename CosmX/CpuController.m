//
//  CpuController.m
//  CosmX
//
//  Created by Levent Ali on 18/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CpuController.h"

@implementation CpuController

- (void)updateCpuInfo:(id)sender
{
    int mib[2U] = { CTL_HW, HW_NCPU };
    size_t sizeOfNumCPUs = sizeof(numCPUs);
    int status = sysctl(mib, 2U, &numCPUs, &sizeOfNumCPUs, NULL, 0U);
    if(status)
        numCPUs = 1;
    
    CPUUsageLock = [[NSLock alloc] init];
    
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                    target:self
                                                  selector:@selector(updateInfo:)
                                                  userInfo:nil
                                                   repeats:YES];    
}

- (void)pause:(id)sender {
    paused = YES;
}

- (void)unpause:(id)sender {
    paused = NO;    
}

- (void)updateInfo:(NSTimer *)timer
{
    if(!paused) {
        myDatastreams = [NSMutableArray arrayWithObjects: nil];
        jsonWriter = [SBJsonWriter new];
        natural_t numCPUsU = 0U;
        kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCpuInfo);
        
        // RAM bunk
        struct task_basic_info info;
        sizeRam = sizeof(info);

        if(err == KERN_SUCCESS) {
            [CPUUsageLock lock];
            

            
            for(unsigned i = 0U; i < numCPUs; ++i) {
                float inUse, total;
                if(prevCpuInfo) {
                    inUse = (
                             (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER]   - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER])
                             + (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM])
                             + (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]   - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE])
                             );
                    total = inUse + (cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
                } else {
                    inUse = cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] + cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] + cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
                    total = inUse + cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
                }
                
                NSString *currentValue = [[NSString alloc] initWithFormat:@"%.2f", (inUse / total) * 100.0];
                NSString *streamId = [[NSString alloc] initWithFormat:@"cpu_%i", i];
                NSDictionary *aDatastreamUnits = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                  @"%", @"symbol", 
                                                  @"Percent", @"label",
                                                  nil];
                NSDictionary *aDatastream = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                  currentValue, @"current_value",
                                                  streamId, @"id",
                                                  @"cpu", @"tags",
                                                  aDatastreamUnits, @"unit",
                                                  nil];

                [myDatastreams insertObject:aDatastream atIndex:i];
            }
            [CPUUsageLock unlock];
            
            if(prevCpuInfo) {
                size_t prevCpuInfoSize = sizeof(integer_t) * numPrevCpuInfo;
                vm_deallocate(mach_task_self(), (vm_address_t)prevCpuInfo, prevCpuInfoSize);
            }
            
            prevCpuInfo = cpuInfo;
            numPrevCpuInfo = numCpuInfo;
            
            cpuInfo = NULL;
            numCpuInfo = 0U;
        } else {
            NSLog(@"Error!");
            [NSApp terminate:nil];
        }
        
        
        // System Version String
        
        NSDictionary *sysVersion = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     [self systemVersionString], @"current_value",
                                     @"mac_os_version", @"id",
                                     nil];
        
        [myDatastreams addObject:sysVersion];
        
        NSString *title = [[NSString alloc] initWithFormat:@"System info (%@)", [[NSHost currentHost] localizedName]];
        NSArray *feedTags = [[NSArray alloc] initWithObjects:@"app:author=lebreeze", @"app:name=CosmX", nil];
        NSDictionary *feed = [[NSDictionary alloc] initWithObjectsAndKeys:
                                title, @"title",
                                feedTags, @"tags",
                                myDatastreams,@"datastreams",
                                @"1.0.0", @"version",
                                nil];
        
        feedId = [[NSUserDefaults standardUserDefaults] objectForKey:@"feedId"];
        apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"apiKey"];
        url = [[NSString alloc] initWithFormat:@"http://api.cosm.com/v2/feeds/%@.json?key=%@", feedId, apiKey];

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        [request setHTTPMethod:@"PUT"];
        NSString *postString = [jsonWriter stringWithObject:feed];
        [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
        connectionCosm = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    }
}


- (NSString *)systemVersionString
{
	// This returns a version string of the form X.Y.Z
	// There may be a better way to deal with the problem that gestaltSystemVersionMajor
	//  et al. are not defined in 10.3, but this is probably good enough.
	NSString* verStr = nil;
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4
	SInt32 major, minor, bugfix;
	OSErr err1 = Gestalt(gestaltSystemVersionMajor, &major);
	OSErr err2 = Gestalt(gestaltSystemVersionMinor, &minor);
	OSErr err3 = Gestalt(gestaltSystemVersionBugFix, &bugfix);
	if (!err1 && !err2 && !err3)
	{
		verStr = [NSString stringWithFormat:@"%ld.%ld.%ld", (long)major, (long)minor, (long)bugfix];
	}
	else
#endif
	{
	 	NSString *versionPlistPath = @"/System/Library/CoreServices/SystemVersion.plist";
		verStr = [[NSDictionary dictionaryWithContentsOfFile:versionPlistPath] objectForKey:@"ProductVersion"];
	}
	return verStr;
}

@end
