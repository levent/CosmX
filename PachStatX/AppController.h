//
//  AppController.h
//  PachStatX
//
//  Created by Levent Ali on 18/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PreferencesController.h"

@interface AppController : NSObject {
    @private
    PreferencesController *preferencesController;
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSImageView *feedGraph;
}

- (IBAction)showPreferences:(id)sender;

@end
