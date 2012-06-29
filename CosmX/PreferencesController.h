//
//  PreferencesController.h
//  CosmX
//
//  Created by Levent Ali on 18/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "oAuthWindowController.h"

@interface PreferencesController : NSWindowController
{
    IBOutlet NSTextField *signupLinkField;
    IBOutlet NSButton *oauthButton;
    oAuthWindowController *oAuthWindow;
}
-(void)setHyperlinkWithTextField:(NSTextField *)inTextField;
-(IBAction)loadOAuthWindow:(id)sender;
@end

@interface NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end
