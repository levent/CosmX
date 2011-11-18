//
//  CpuController.m
//  PachStatX
//
//  Created by Levent Ali on 18/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CpuController.h"

@implementation CpuController

- (void)updateCpuInfo:(id)sender
{
    feedId = [[NSUserDefaults standardUserDefaults] objectForKey:@"feedId"];
    apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"apiKey"];
    url = [[NSString alloc] initWithFormat:@"http://api.pachube.com/v2/feeds/%@.json?key=%@", feedId, apiKey]; 
    NSLog(@"win");
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

- (void)updateInfo:(NSTimer *)timer
{
    myDatastreams = [NSMutableArray arrayWithObjects: nil];
    jsonWriter = [SBJsonWriter new];
    natural_t numCPUsU = 0U;
    kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCpuInfo);
    
    // RAM bunk
    struct task_basic_info info;
    sizeRam = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &sizeRam);


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
            NSDictionary *aDatastream = [[NSDictionary alloc] initWithObjectsAndKeys:
                                              currentValue, @"current_value",
                                              streamId, @"id",
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

    
    if(kerr == KERN_SUCCESS) {
        NSString *currentValue = [[NSString alloc] initWithFormat:@"%u", info.resident_size];
        NSString *streamId = [[NSString alloc] initWithFormat:@"memory"];
        
        NSDictionary *aDatastream = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     currentValue, @"current_value",
                                     streamId, @"id",
                                     nil];
        
        [myDatastreams addObject:aDatastream];
    }
    
    NSDictionary *feed = [[NSDictionary alloc] initWithObjectsAndKeys:
                            @"System info", @"title",
                            myDatastreams,@"datastreams",
                            @"1.0.0", @"version",
                            nil];
    

//    NSMutableData *responseData = [NSMutableData data];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"PUT"];
    NSString *postString = [jsonWriter stringWithObject:feed];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

@end
