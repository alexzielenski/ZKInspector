//
//  AppDelegate.m
//  ZKInspector
//
//  Created by Alexander Zielenski on 8/10/14.
//  Copyright (c) 2014 Alexander Zielenski. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () <ZKInspectorDelegate>

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate
            
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.inspector.delegate = self;
    // Insert code here to initialize your application
    [self.inspector addView:nil withTitle:@"View 1"];
    [self.inspector addView:self.view2 withTitle:@"View 2"];

    
    [self.inspector setTitle:@"New Title" forIndex:0];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)inspector:(ZKInspector *)inspector shouldExpandView:(NSView *)view withTitle:(NSString *)title atIndex:(NSUInteger)index {
    return index != 0;
}

- (void)inspector:(ZKInspector *)inspector didExpandView:(NSView *)view withTitle:(NSString *)title atIndex:(NSUInteger)index {
    if (index == 1 && inspector.numberOfViews == 2) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.inspector addView:self.view3 withTitle:@"View 3"];
            [self.inspector setView:self.view1 forIndex:1];
        });
    } else if (index == 2) {
        if (![[self.inspector titleAtIndex:1] isEqualToString:@"SAP"])
            [self.inspector setTitle:@"SAP" forIndex:1];
        [self.inspector moveViewAtIndex:0 toIndex:1];
    }
}

@end
