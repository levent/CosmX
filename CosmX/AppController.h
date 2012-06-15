//
//  AppController.h
//  CosmX
//
//  Created by Levent Ali on 18/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBJson.h"
#import "PreferencesController.h"
#import "CpuController.h"

@interface AppController : NSObject {
    @private
    PreferencesController *preferencesController;
    CpuController *cpuController;
//    IBOutlet NSWindow *mainWindow;
//    IBOutlet NSImageView *feedGraph;
    NSStatusItem *statusItem;
    IBOutlet NSMenu *statusMenu;
    
    IBOutlet NSMenuItem *isRunning;
    IBOutlet NSMenuItem *turnOffMenuItem;
    IBOutlet NSMenuItem *turnOnMenuItem;
    
    IBOutlet NSMenuItem *viewFeedMenuItem;
    NSString *feedURL;
    NSImage *onImage;
    NSImage *offImage;
}

- (IBAction)showPreferences:(id)sender;
- (IBAction)turnOff:(id)sender;
- (IBAction)turnOn:(id)sender;
- (IBAction)viewFeed:(id)sender;

@end
