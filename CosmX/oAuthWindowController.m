//
//  oAuthWindowController.m
//  CosmX
//
//  Created by Levent Ali on 29/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "oAuthWindowController.h"

@implementation oAuthWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [[webview mainFrame] loadRequest:[self authOnCosm]];
//    [[webview mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://cosm.com/oauth/authenticate?client_id=8cc441f3624c52bdda5c"]]];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSURLRequest *)authOnCosm
{
    NSMutableURLRequest *authRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://cosm.com/oauth/authenticate?client_id=8cc441f3624c52bdda5c"]];
    [[NSURLConnection alloc] initWithRequest:authRequest delegate:self];
    return [authRequest copy];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog([[response URL] parameterString]);
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"apple");
}

@end
