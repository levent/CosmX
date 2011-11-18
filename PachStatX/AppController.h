//
//  AppController.h
//  PachStatX
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
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSImageView *feedGraph;
    NSStatusItem *statusItem;
    IBOutlet NSMenu *statusMenu;
}

- (IBAction)showPreferences:(id)sender;

@end
