//
//  AppController.m
//  PachStatX
//
//  Created by Levent Ali on 18/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"

@implementation AppController

-(IBAction)turnOn:(id)sender {
    [turnOnMenuItem setHidden:YES];
    [turnOffMenuItem setHidden:NO];
    [isRunning setTitle:@"Running..."];
    [cpuController unpause:self];
//    NSLog(@"%c on", [turnOnMenuItem isHidden]);
//    NSLog(@"%c off", [turnOffMenuItem isHidden]);    
}

-(IBAction)turnOff:(id)sender {
    [turnOnMenuItem setHidden:NO];
    [turnOffMenuItem setHidden:YES];
    [isRunning setTitle:@"Stopped..."];
    [cpuController pause:self];
//    NSLog(@"%c on", [turnOnMenuItem isHidden]);
//    NSLog(@"%c off", [turnOffMenuItem isHidden]);
}

-(IBAction)showPreferences:(id)sender {
    if(!preferencesController)
        preferencesController = [[PreferencesController alloc] initWithWindowNibName:@"Preferences"];
    [preferencesController showWindow:self];
}

-(void)awakeFromNib {
    
    if(!cpuController)
        cpuController = [[CpuController alloc] init];
    
    [cpuController updateCpuInfo:self];
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
    [statusItem setTitle:@"PachStatX"];
    [statusItem setHighlightMode:YES];
    
    NSString *feedId = [[NSUserDefaults standardUserDefaults] objectForKey:@"feedId"];
    NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"apiKey"];
    NSLog(@"%@ %@", feedId, apiKey);
    NSString *url = [[NSString alloc] initWithFormat:@"http://api.pachube.com/v2/feeds/%@/datastreams/0.png?duration=24hours&width=%.0f&height=%.0f&show_axis_labels=rel&colour=000000", feedId, feedGraph.frame.size.width, feedGraph.frame.size.height];
    NSLog(@"%@", url);
    NSData *receivedGraph = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    NSImage *image = [[NSImage alloc] initWithData:receivedGraph];
//    feedGraph.image = image;
    [feedGraph setImage:image];
//    feedGraph.image = image;
//    navigationBarTitle.title = [[NSString alloc] initWithFormat:@"Feed: %@", feedId];

}

//-(void)dealloc {
//    [preferencesController release];
//    [super dealloc];
//}

@end
