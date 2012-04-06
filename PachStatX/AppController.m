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
}

-(IBAction)turnOff:(id)sender {
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
    feedURL = [[NSString alloc] initWithFormat:@"https://cosm.com/feeds/%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"feedId"]]; 
    NSURL *url = [NSURL URLWithString:feedURL];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

-(void)awakeFromNib {
    
    if(!cpuController)
        cpuController = [[CpuController alloc] init];
    
    [cpuController updateCpuInfo:self];

    NSImage *statusImage = [NSImage imageNamed:@"logo-stamp.png"];
//    NSSize imageSize;
//    imageSize = [statusImage size];
//    imageSize.height /= 2.6;
//    imageSize.width /= 2.6;
//    [statusImage setSize:imageSize];
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
//    [statusItem setTitle:@"PachStatX"];
    [statusItem setImage:statusImage];
    [statusItem setHighlightMode:YES];
}

@end
