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
    self.inspector.inspectorDelegate = self;
    // Insert code here to initialize your application
    [self.inspector addView:[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 0, 1)] withTitle:@"View 1" expanded:NO];
    [self.inspector addView:self.view2 withTitle:@"View 2" expanded:NO];

    
    [self.inspector setTitle:@"New Title" forIndex:0];
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
}

- (void)timerAction:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSRect f = self.view1.frame;
        f.size.height += 10;
        self.view1.frame = f;
    });

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)inspector:(ZKInspector *)inspector shouldExpandView:(NSView *)view withTitle:(NSString *)title atIndex:(NSUInteger)index {
    return index != 0;
}

- (void)inspector:(ZKInspector *)inspector didExpandView:(NSView *)view withTitle:(NSString *)title atIndex:(NSUInteger)index {
    if (index == 1 && inspector.numberOfViews == 2) {
        static BOOL dispatched = NO;
        if (!dispatched) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.inspector addView:self.view3 withTitle:@"View 3" expanded:YES];
                [self.inspector setView:self.view1 forIndex:1];
            });
            dispatched = YES;
        }
    } else if (index == 2) {
        [self.inspector setTitle:[[NSUUID UUID] UUIDString] forIndex:1];
        [self.inspector moveViewAtIndex:0 toIndex:1];
    }
}

@end
