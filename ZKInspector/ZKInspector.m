//
//  ZKInspector.m
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

#import "ZKInspector.h"

#define kDefaultHeaderHeight 22.0

@interface ZKTitleRowView : NSTableRowView
@end

@implementation ZKTitleRowView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [[NSColor grayColor] set];
    NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));
    NSRectFill(NSMakeRect(0, NSMaxY(self.bounds) - 1, self.bounds.size.width, 1));
}

@end

@interface ZKInspectorItem : NSObject
@property (copy) NSString *title;
@property (strong) NSView *view;
@property (strong) NSTableCellView *cellView;
@property (strong) ZKTitleRowView *titleRowView;
@end

@implementation ZKInspectorItem

- (id)init {
    if ((self = [super init])) {
        self.cellView = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, 250, 30)];
        NSTextField *textField = [[NSTextField alloc] initWithFrame:self.cellView.frame];
        textField.selectable = NO;
        textField.editable = NO;
        textField.bezeled = NO;
        textField.drawsBackground = NO;
        
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        self.cellView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.cellView addSubview:textField];
        self.cellView.textField = textField;
        
        [textField bind:NSValueBinding toObject:self withKeyPath:@"title" options:nil];
        self.titleRowView = [[ZKTitleRowView alloc] initWithFrame:NSZeroRect];
    }
    
    return self;
}

@end


@interface ZKInspector () <NSOutlineViewDataSource, NSOutlineViewDelegate>
@property (strong) NSOutlineView *outlineView;
@property (strong) NSMutableArray *items;
- (void)_initialize;
- (ZKInspectorItem *)itemForView:(NSView *)view;
- (ZKInspectorItem *)itemForTitle:(NSString *)title;
@end

@implementation ZKInspector

- (id)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        [self _initialize];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        [self _initialize];
    }
    
    return self;
}

- (id)init {
    if ((self = [super init])) {
        [self _initialize];
    }
    
    return self;
}

- (void)_initialize {
    self.headerHeight = kDefaultHeaderHeight;
    
    self.items = [NSMutableArray array];
    self.hasVerticalScroller = YES;
    self.hasHorizontalScroller = YES;
    self.autohidesScrollers = NO;
    
    //! When I programmatically created the outline view sometimes its content would not show up? (datasource methods do get called)
    //! I'll chalk that up to an devtools bug. For now, just create an outline view as you normall would
    //! in IB and set its scrollview class to this
    //! This is here just in case you choose to go another route and try your luck with the bug
    if (![self.documentView isKindOfClass:[NSOutlineView class]]) {
        self.outlineView = [[NSOutlineView alloc] initWithFrame:NSMakeRect(0, 0, 10, 10)];
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"ZKInspectorColumn"];
        column.editable = NO;
        [self.outlineView addTableColumn:column];
        self.outlineView.outlineTableColumn = column;
        [self.outlineView setAutoresizesOutlineColumn:YES];
        
        self.documentView = self.outlineView;
    }
    
    self.outlineView = self.documentView;
    
    self.outlineView.rowSizeStyle = NSTableViewRowSizeStyleMedium;
    self.outlineView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleSourceList;
    self.outlineView.intercellSpacing = NSZeroSize;
    self.outlineView.floatsGroupRows = NO;
    self.outlineView.indentationPerLevel = 0.0;
    self.outlineView.headerView = nil;
    self.outlineView.allowsColumnReordering = NO;
    self.outlineView.allowsColumnResizing = NO;
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    
    self.outlineView.delegate = self;
    self.outlineView.dataSource = self;
    [self.outlineView reloadData];
}

#pragma mark - Actions

- (void)addView:(NSView *)view withTitle:(NSString *)title {
    [self insertView:view withTitle:title atIndex:self.items.count];
}

- (void)insertView:(NSView *)view withTitle:(NSString *)title atIndex:(NSUInteger)index {
    NSAssert([self itemForTitle:title] == nil && [self itemForView:view] == nil, @"Every view in ZKInspector must have a unique title and view (%@, %@)", title, view);
    
    ZKInspectorItem *item = [[ZKInspectorItem alloc] init];
    item.title = title;
    item.view = view;
    
    [self.items insertObject:item atIndex:index];
    [self.outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:nil withAnimation:NSTableViewAnimationSlideDown];
}

- (NSString *)titleForView:(NSView *)view {
    return [self itemForView:view].title;
}

- (NSView *)viewForTitle:(NSString *)title {
    return [self itemForTitle:title].view;
}

- (NSString *)titleAtIndex:(NSUInteger)index {
    return [self.items[index] title];
}

- (NSView *)viewAtIndex:(NSUInteger)index {
    return [self.items[index] view];
}

- (NSUInteger)numberOfViews {
    return self.items.count;
}

- (void)setView:(NSView *)view forTitle:(NSString *)title {
    NSAssert([self itemForView:view] == nil,  @"Every view in ZKInspector must have a unique title and view (%@)", view);
    ZKInspectorItem *item = [self itemForTitle:title];
    item.view = view;
    [self.outlineView reloadItem:item reloadChildren:YES];
}

- (void)setTitle:(NSString *)title forView:(NSView *)view {
    NSAssert([self itemForTitle:title] == nil,  @"Every view in ZKInspector must have a unique title and view (%@)", title);
    ZKInspectorItem *item = [self itemForView:view];
    item.title = title;
}

- (void)setView:(NSView *)view forIndex:(NSUInteger)index {
    NSAssert([self itemForView:view] == nil,  @"Every view in ZKInspector must have a unique title and view (%@)", view);
    ZKInspectorItem *item = self.items[index];
    item.view = view;
    [self.outlineView reloadItem:item reloadChildren:YES];
}

- (void)setTitle:(NSString *)title forIndex:(NSUInteger)index {
    NSAssert([self itemForTitle:title] == nil,  @"Every view in ZKInspector must have a unique title and view (%@)", title);
    ZKInspectorItem *item = self.items[index];
    item.title = title;
}

- (void)removeViewAtIndex:(NSUInteger)index {
    [self.items removeObjectAtIndex:index];
    [self.outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:nil withAnimation:NSTableViewAnimationEffectGap];
}

- (void)moveViewAtIndex:(NSUInteger)index toIndex:(NSUInteger)destinationIndex {
    __strong ZKInspectorItem *item = self.items[index];
    if (index < destinationIndex)
        destinationIndex--;
    
    [self.items removeObjectAtIndex:index];
    [self.items insertObject:item atIndex:destinationIndex];
    
    [self.outlineView moveItemAtIndex:index inParent:nil toIndex:destinationIndex+1 inParent:nil];
}

#pragma mark - Private

- (ZKInspectorItem *)itemForView:(NSView *)view {
    return [[self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"view == %@", view]] firstObject];
}

- (ZKInspectorItem *)itemForTitle:(NSString *)title {
    return [[self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"title == %@", title]] firstObject];
}

#pragma mark - NSOutlineViewDataSource

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil)
        return self.items[index];
    
    return ((ZKInspectorItem *)item).view;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil)
        return self.items.count;
    return [self outlineView:outlineView isGroupItem:item] ? 1: 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(ZKInspectorItem *)item {
    return [self outlineView:outlineView isGroupItem:item];
}

#pragma mark - NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return [item isKindOfClass:[ZKInspectorItem class]];
}


- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item {
    if ([self outlineView:outlineView isGroupItem:item]) {
        return ((ZKInspectorItem *)item).titleRowView;
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    // required
}

- (void)outlineView:(NSOutlineView *)outlineView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    // required
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([self outlineView:outlineView isGroupItem:item]) {
        return [item valueForKey:@"cellView"];
    }
    
    return item;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return NO;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    if ([self outlineView:outlineView isGroupItem:item]) {
        return self.headerHeight;
    }
    
    return ((NSView *)item).bounds.size.height;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(ZKInspectorItem *)item {
    if ([self.delegate respondsToSelector:@selector(inspector:shouldExpandView:withTitle:atIndex:)]) {
        return [self.delegate inspector:self shouldExpandView:item.view withTitle:item.title atIndex:[self.items indexOfObject:item]];
    }
    
    return YES;
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(inspector:didExpandView:withTitle:atIndex:)]) {
        ZKInspectorItem *item = notification.userInfo[@"NSObject"];
        [self.delegate inspector:self didExpandView:item.view withTitle:item.title atIndex:[self.items indexOfObject:item]];
    }

}

@end
