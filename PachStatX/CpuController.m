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
//- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{    
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
            
//            NSLog(@"Core: %u Usage: %f",i,inUse / total);
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
    
//    {"status":"frozen","location":{"domain":"physical"},"feed":"https://api.pachube.com/v2/feeds/38997.json","creator":"https://pachube.com/users/lebreeze","title":"test","private":"false","datastreams":[{"max_value":"144.0","at":"2011-11-17T14:41:59.538876Z","min_value":"25.0","current_value":"111","id":"0"}],"id":38997,"version":"1.0.0","updated":"2011-11-17T14:41:59.538876Z"}
    NSDictionary *feed = [[NSDictionary alloc] initWithObjectsAndKeys:
                            @"System info", @"title",
                            myDatastreams,@"datastreams",
                            @"1.0.0", @"version",
                            nil];
    NSLog([jsonWriter stringWithObject:feed]);
    
    
    NSString *feedId = [[NSUserDefaults standardUserDefaults] objectForKey:@"feedId"];
//    NSString *streamId = [[NSUserDefaults standardUserDefaults] objectForKey:@"streamId"];
    NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"apiKey"];
    
    NSString *url = [[NSString alloc] initWithFormat:@"http://api.pachube.com/v2/feeds/%@.json?key=%@", feedId, apiKey]; 
    NSMutableData *responseData = [NSMutableData data];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"PUT"];
    NSString *postString = [jsonWriter stringWithObject:feed];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    [[NSURLConnection alloc] initWithRequest:request delegate:self];
//    for (i = 0; i < count; i++)
//        NSLog (@"Element %i = %@", i, [myDatastreams objectAtIndex: i]);
}

@end
