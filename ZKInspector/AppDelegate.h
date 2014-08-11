//
//  AppDelegate.h
//  ZKInspector
//
//  Created by Alexander Zielenski on 8/10/14.
//  Copyright (c) 2014 Alexander Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ZKInspector.h"
@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (weak) IBOutlet NSView *view1;
@property (weak) IBOutlet NSView *view2;
@property (weak) IBOutlet NSView *view3;
@property (weak) IBOutlet ZKInspector *inspector;
@end

