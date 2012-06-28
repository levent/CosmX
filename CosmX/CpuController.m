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

- (NSDictionary *)cpuDatastreamUnits
{
    return [[NSDictionary alloc] initWithObjectsAndKeys:
     @"%", @"symbol", 
     @"Percent", @"label",
     nil];
}

- (NSDictionary *)ramUnits
{
    return [[NSDictionary alloc] initWithObjectsAndKeys:
            @"(MB)", @"symbol", 
            @"Megabytes", @"label",
            nil];
}

- (NSString *)feedTitle
{
    return [[NSString alloc] initWithFormat:@"CosmX System Info (%@)", [[NSHost currentHost] localizedName]];
}

- (NSString *)feedDescription
{
    return [[NSString alloc] initWithFormat:@"%@\r\n\r\nhttps://github.com/levent/CosmX", [self cpuType]];
}

- (NSArray *)feedTags
{
    NSString *osVersionTag = [[NSString alloc] initWithFormat:@"os:version=%@", [self systemVersion]];
    return [[NSArray alloc] initWithObjects:@"app:author=lebreeze", @"app:name=CosmX", osVersionTag, @"os:type=osx", nil];
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
                NSDictionary *aDatastream = [[NSDictionary alloc] initWithObjectsAndKeys:
                                             currentValue, @"current_value",
                                             streamId, @"id",
                                             @"cpu", @"tags",
                                             [self cpuDatastreamUnits], @"unit",
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
        
        // CPU Count
        NSDictionary *cpuCount = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  [self cpuCount], @"current_value",
                                  @"cpu_count", @"id",
                                  nil];
        
        // Total RAM
        NSDictionary *totalRam = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  [self totalRam], @"current_value",
                                  @"total_memory", @"id",
                                  [self ramUnits], @"unit",
                                  nil];
        
        [myDatastreams addObject:totalRam];
        [myDatastreams addObject:cpuCount];
        
        NSDictionary *feed = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [self feedTitle], @"title",
                              [self feedDescription], @"description",
                              [self feedTags], @"tags",
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


- (NSString *)systemVersion
{
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

- (NSString *)cpuType
{
    int error = 0;
    char buf[100];
    size_t buflen = 100;
    
    NSString *cpuBrandString;
    
    error = sysctlbyname("machdep.cpu.brand_string", &buf, &buflen, NULL, 0);
    
    if (error == 0)
    {
        cpuBrandString = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
    }
    return [NSString stringWithFormat:@"%@", cpuBrandString];
}

- (NSString *)cpuCount
{
    int error = 0;
    int value = 0;
    size_t length = sizeof(value);
    
    NSString *cpuCount;
    
	error = sysctlbyname("hw.ncpu", &value, &length, NULL, 0);
	if (error == 0) {
        cpuCount = [NSString stringWithFormat:@"%@", [NSNumber numberWithInt:value]];
    }
    return cpuCount;
}

- (NSString *)totalRam
{
    NSString *ram;
    SInt32 gestaltInfo;
	OSErr err = Gestalt(gestaltPhysicalRAMSizeInMegabytes,&gestaltInfo);
    if (err == noErr) {
        ram = [NSString stringWithFormat:@"%@", [NSNumber numberWithInt:gestaltInfo]];
    }
    return ram;
}

// TODO: Make this work
//- (NSString *)usedRam
//{
//    int mib[6]; 
//    mib[0] = CTL_HW;
//    mib[1] = HW_PAGESIZE;
//    
//    int pagesize;
//    size_t length;
//    length = sizeof (pagesize);
//    if (sysctl (mib, 2, &pagesize, &length, NULL, 0) < 0)
//    {
//        fprintf (stderr, "getting page size");
//    }
//    
//    mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
//    
//    vm_statistics_data_t vmstat;
//    if (host_statistics (mach_host_self (), HOST_VM_INFO, (host_info_t) &vmstat, &count) != KERN_SUCCESS)
//    {
//        fprintf (stderr, "Failed to get VM statistics.");
//    }
//    
//    double total = vmstat.wire_count + vmstat.active_count + vmstat.inactive_count + vmstat.free_count;
//    double wired = vmstat.wire_count / total;
//    double active = vmstat.active_count / total;
//    double inactive = vmstat.inactive_count / total;
//    double free = vmstat.free_count / total;
//    
//    task_basic_info_64_data_t info;
//    unsigned size = sizeof (info);
//    task_info (mach_task_self (), TASK_BASIC_INFO_64, (task_info_t) &info, &size);
//    
//    double unit = 1024 * 1024;
//    return [NSString stringWithFormat: @"% 3.1f MB\n% 3.1f MB\n% 3.1f MB", vmstat.free_count * pagesize / unit, (vmstat.free_count + vmstat.inactive_count) * pagesize / unit, info.resident_size / unit];
//}
@end
