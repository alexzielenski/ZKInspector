ZKInspector
===========

An NSOutlineView subclass for 10.9+ that gets you a collapsable stack of views like Xcode's inspector.

![Preview](https://github.com/alexzielenski/ZKInspector/raw/master/preview.png "Preview")

Usage
=====

Create an `NSOutlineView` as you normally would in interface builder then simply change its class to `ZKInspector`

```objc
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.inspector.inspectorDelegate = self;
    // Insert code here to initialize your application
    [self.inspector addView:[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 0, 1)] withTitle:@"View 1"];
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
        static BOOL dispatched = NO;
        if (!dispatched) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.inspector addView:self.view3 withTitle:@"View 3"];
                [self.inspector setView:self.view1 forIndex:1];
            });
            dispatched = YES;
        }
    } else if (index == 2) {
        [self.inspector setTitle:[[NSUUID UUID] UUIDString] forIndex:1];
        [self.inspector moveViewAtIndex:0 toIndex:1];
    }
}

- (CGFloat)inspector:(ZKInspector *)inspector heightForView:(NSView *)view withTitle:(NSString *)title atIndex:(NSUInteger)index {
    return 132.0;
}


```

License
=======

ZKInspector is licensed under BSD

Copyright (c) 2014, Alex Zielenski
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
