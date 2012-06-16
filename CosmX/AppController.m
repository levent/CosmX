//
//  AppController.m
//  CosmX
//
//  Created by Levent Ali on 18/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"

@implementation AppController

-(IBAction)turnOn:(id)sender {
    [statusItem setImage:onImage];
    [turnOnMenuItem setHidden:YES];
    [turnOffMenuItem setHidden:NO];
    [isRunning setTitle:@"Running..."];
    [cpuController unpause:self];
}

-(IBAction)turnOff:(id)sender {
    [statusItem setImage:offImage];
    [turnOnMenuItem setHidden:NO];
    [turnOffMenuItem setHidden:YES];
    [isRunning setTitle:@"Stopped..."];
    [cpuController pause:self];
}

-(IBAction)showPreferences:(id)sender {
    if(!preferencesController)
        preferencesController = [[PreferencesController alloc] initWithWindowNibName:@"Preferences"];
    [preferencesController showWindow:self];
}

-(IBAction)viewFeed:(id)sender {
    NSString *feedId = [[NSUserDefaults standardUserDefaults] objectForKey:@"feedId"];
    if (feedId.length != 0) {
        feedURL = [[NSString alloc] initWithFormat:@"https://cosm.com/feeds/%@", feedId]; 
        NSURL *url = [NSURL URLWithString:feedURL];
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

-(void)awakeFromNib {
    
    if(!cpuController)
        cpuController = [[CpuController alloc] init];
    
    [cpuController updateCpuInfo:self];

    onImage = [NSImage imageNamed:@"logo-stamp.png"];
    offImage = [NSImage imageNamed:@"logo-stamp-bw.png"];
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
    [statusItem setImage:onImage];
    [statusItem setHighlightMode:YES];
}

@end
