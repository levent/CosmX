//
//  oAuthWindowController.h
//  CosmX
//
//  Created by Levent Ali on 29/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface oAuthWindowController : NSWindowController
{
    IBOutlet WebView *webview;
}

- (NSURLRequest *)authOnCosm;
@end
