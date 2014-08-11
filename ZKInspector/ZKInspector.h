//
//  ZKInspector.h
//  ZKInspector
//
// Copyright (c) 2014, Alex Zielenski
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//          SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Cocoa/Cocoa.h>

@class ZKInspector;
@protocol ZKInspectorDelegate <NSObject>

@optional
- (BOOL)inspector:(ZKInspector *)inspector shouldExpandView:(NSView *)view withTitle:(NSString *)title atIndex:(NSUInteger)index;
- (void)inspector:(ZKInspector *)inspector didExpandView:(NSView *)view withTitle:(NSString *)title atIndex:(NSUInteger)index;

@end

@interface ZKInspector : NSScrollView
@property (weak) id <ZKInspectorDelegate> delegate;
@property (assign) CGFloat headerHeight; // defaults to 22
- (void)addView:(NSView *)view withTitle:(NSString *)title;
- (void)insertView:(NSView *)view withTitle:(NSString *)title atIndex:(NSUInteger)index;

- (NSString *)titleForView:(NSView *)view;
- (NSView *)viewForTitle:(NSString *)title;

- (NSString *)titleAtIndex:(NSUInteger)index;
- (NSView *)viewAtIndex:(NSUInteger)index;

- (NSUInteger)numberOfViews;

- (void)setView:(NSView *)view forTitle:(NSString *)title;
- (void)setTitle:(NSString *)title forView:(NSView *)view;

- (void)setView:(NSView *)view forIndex:(NSUInteger)index;
- (void)setTitle:(NSString *)title forIndex:(NSUInteger)index;

- (void)removeViewAtIndex:(NSUInteger)index;
- (void)moveViewAtIndex:(NSUInteger)index toIndex:(NSUInteger)destinationIndex;

@end
