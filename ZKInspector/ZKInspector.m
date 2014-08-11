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

#define kDefaultHeaderHeight 24.0

@class ZKInspectorItem;
@interface ZKTitleRowView : NSTableRowView
@property (weak) NSButton *toggleButton;
@property (weak) NSTableCellView *cell;
@property (weak) ZKInspectorItem *item;
@property (weak) NSOutlineView *outlineView;
@end


@interface ZKInspectorItem : NSObject
@property (copy) NSString *title;
@property (strong) NSView *view;
@property (strong) NSTableCellView *cellView;
@property (strong) ZKTitleRowView *titleRowView;
@property (assign, getter=isExpanded) BOOL expanded;
@end

@implementation ZKTitleRowView


- (void)layout {
    if (!self.toggleButton || !self.cell) {
        NSButton *toggleButton = nil;
        NSTableCellView *cell = nil;
        for (NSView *subview in self.subviews) {
            if ([subview isKindOfClass:[NSButton class]])
                toggleButton = (NSButton *)subview;
            else if ([subview isKindOfClass:[NSTableCellView class]])
                cell = (NSTableCellView *)subview;
        }
        self.toggleButton = toggleButton;
        self.cell = cell;
        
    }

    if (self.toggleButton && self.cell) {
        NSRect f = self.cell.frame;
        f.origin.x = 8;
        f.size.width = self.bounds.size.width - self.toggleButton.frame.size.width - 24;
        f.origin.y = NSMidY(self.bounds) - f.size.height / 2;
        
        self.cell.frame = f;
        
        f = self.toggleButton.frame;
        f.origin.y = NSMidY(self.bounds) - f.size.height / 2;
        self.toggleButton.frame = f;
    }
    
    [super layout];
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor lightGrayColor] set];

    NSUInteger row = [self.outlineView rowForItem:self.item];
    if (!self.item.isExpanded) {
        NSRectFill(NSMakeRect(0, NSMaxY(self.bounds) - 1, self.bounds.size.width, 1));
    }
    
    if (row != 0) {
        NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));
    }
}

@end

@implementation ZKInspectorItem

- (id)init {
    if ((self = [super init])) {
        self.cellView = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, 250, kDefaultHeaderHeight)];

        NSTextField *textField = [[NSTextField alloc] initWithFrame:self.cellView.frame];
        textField.selectable = NO;
        textField.editable = NO;
        textField.bezeled = NO;
        textField.drawsBackground = NO;
        
//        textField.translatesAutoresizingMaskIntoConstraints = NO;
//        self.cellView.translatesAutoresizingMaskIntoConstraints = NO;
        self.cellView.rowSizeStyle = NSTableViewRowSizeStyleLarge;
        [self.cellView addSubview:textField];
        self.cellView.textField = textField;
        
        [textField bind:NSValueBinding toObject:self withKeyPath:@"title" options:nil];
        self.titleRowView = [[ZKTitleRowView alloc] initWithFrame:NSZeroRect];
    }
    
    return self;
}

@end


@interface ZKInspector () <NSOutlineViewDataSource, NSOutlineViewDelegate>
@property (strong) NSMutableArray *items;
- (void)_initialize;
- (ZKInspectorItem *)_itemForView:(NSView *)view;
- (ZKInspectorItem *)_itemForTitle:(NSString *)title;
- (void)_expandItem:(ZKInspectorItem *)item;
- (void)_collapseItem:(ZKInspectorItem *)item;
- (void)_setView:(NSView *)view forItem:(ZKInspectorItem *)item;
- (void)_setTitle:(NSString *)title forItem:(ZKInspectorItem *)item;
- (void)_removeItem:(ZKInspectorItem *)item;
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

    if (!self.outlineTableColumn) {
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"ZKInspectorColumn"];
        column.editable = NO;
        [self addTableColumn:column];
    }
    
        self.outlineTableColumn = self.tableColumns[0];
    [self setAutoresizesOutlineColumn:YES];
    
    
    self.rowSizeStyle = NSTableViewRowSizeStyleMedium;
    self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleSourceList;
    self.intercellSpacing = NSZeroSize;
    self.floatsGroupRows = NO;
    self.indentationPerLevel = 0.0;
    self.headerView = nil;
    self.allowsColumnReordering = NO;
    self.gridStyleMask = NSTableViewGridNone;
    self.allowsColumnResizing = NO;
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    
    self.delegate = self;
    self.dataSource = self;
    [self reloadData];
}

#pragma mark - Actions

- (void)addView:(NSView *)view withTitle:(NSString *)title {
    [self insertView:view withTitle:title atIndex:self.items.count];
}

- (void)insertView:(NSView *)view withTitle:(NSString *)title atIndex:(NSUInteger)index {
    NSAssert([self _itemForTitle:title] == nil && [self _itemForView:view] == nil, @"Every view in ZKInspector must have a unique title and view (%@, %@)", title, view);
    
    ZKInspectorItem *item = [[ZKInspectorItem alloc] init];
    item.title = title;
    item.view = view;
    
    [self.items insertObject:item atIndex:index];
    [self insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:nil withAnimation:NSTableViewAnimationSlideDown];
}

- (NSString *)titleForView:(NSView *)view {
    return [self _itemForView:view].title;
}

- (NSView *)viewForTitle:(NSString *)title {
    return [self _itemForTitle:title].view;
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
    [self _setView:view forItem:[self _itemForTitle:title]];
}

- (void)setTitle:(NSString *)title forView:(NSView *)view {
    [self _setTitle:title forItem:[self _itemForView:view]];
}

- (void)setView:(NSView *)view forIndex:(NSUInteger)index {
    [self _setView:view forItem:self.items[index]];
}

- (void)setTitle:(NSString *)title forIndex:(NSUInteger)index {
    [self _setTitle:title forItem:self.items[index]];
}

- (void)removeView:(NSView *)view {
    [self _removeItem:[self _itemForView:view]];
}

- (void)removeViewWithTitle:(NSString *)title {
    [self _removeItem:[self _itemForTitle:title]];
}

- (void)removeViewAtIndex:(NSUInteger)index {
    [self.items removeObjectAtIndex:index];
    [self removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:nil withAnimation:NSTableViewAnimationEffectGap];
}

- (void)moveViewAtIndex:(NSUInteger)index toIndex:(NSUInteger)destinationIndex {
    __strong ZKInspectorItem *item = self.items[index];
    
    [self.items removeObjectAtIndex:index];
    [self.items insertObject:item atIndex:destinationIndex];
    
    [self moveItemAtIndex:index inParent:nil toIndex:destinationIndex inParent:nil];
}

- (void)expandViewForTitle:(NSString *)title {
    [self _expandItem:[self _itemForTitle:title]];
}

- (void)expandViewAtIndex:(NSUInteger)index {
    [self _expandItem:self.items[index]];
}

- (void)expandView:(NSView *)view {
    [self _expandItem:[self _itemForView:view]];
}

- (void)collapseViewForTitle:(NSString *)title {
    [self _collapseItem:[self _itemForTitle:title]];
}

- (void)collapseViewAtIndex:(NSUInteger)index {
    [self _collapseItem:self.items[index]];
}

- (void)collapseView:(NSView *)view {
    [self _collapseItem:[self _itemForView:view]];
}

- (BOOL)validateProposedFirstResponder:(NSResponder *)responder forEvent:(NSEvent *)event {
    return YES;
}

#pragma mark - Private

- (ZKInspectorItem *)_itemForView:(NSView *)view {
    return [[self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"view == %@", view]] firstObject];
}

- (ZKInspectorItem *)_itemForTitle:(NSString *)title {
    return [[self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"title == %@", title]] firstObject];
}

- (void)_expandItem:(ZKInspectorItem *)item {
    [self expandItem:item];
}

- (void)_collapseItem:(ZKInspectorItem *)item {
    [self collapseItem:item];
}

- (void)_setView:(NSView *)view forItem:(ZKInspectorItem *)item {
    NSAssert([self _itemForView:view] == nil,  @"Every view in ZKInspector must have a unique title and view (%@)", view);
    item.view = view;
    [self reloadItem:item reloadChildren:YES];
}

- (void)_setTitle:(NSString *)title forItem:(ZKInspectorItem *)item {
    NSAssert([self _itemForTitle:title] == nil,  @"Every view in ZKInspector must have a unique title and view (%@)", title);
    item.title = title;
}

- (void)_removeItem:(ZKInspectorItem *)item {
    [self removeViewAtIndex:[self.items indexOfObject:item]];
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
        ZKTitleRowView *rowView = ((ZKInspectorItem *)item).titleRowView;
        rowView.outlineView = outlineView;
        rowView.item = item;
        return rowView;
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    // required
}

- (void)outlineView:(NSOutlineView *)outlineView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    // required
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(NSView *)item {
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
    
    return ((NSView *)item).frame.size.height;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(ZKInspectorItem *)item {
    if ([self.inspectorDelegate respondsToSelector:@selector(inspector:shouldExpandView:withTitle:atIndex:)]) {
        return [self.inspectorDelegate inspector:self shouldExpandView:item.view withTitle:item.title atIndex:[self.items indexOfObject:item]];
    }
    
    return YES;
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification {
    ZKInspectorItem *item = notification.userInfo[@"NSObject"];
    item.expanded = YES;
    
    if ([self.inspectorDelegate respondsToSelector:@selector(inspector:didExpandView:withTitle:atIndex:)]) {
        [self.inspectorDelegate inspector:self didExpandView:item.view withTitle:item.title atIndex:[self.items indexOfObject:item]];
    }
    
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(ZKInspectorItem *)item {
    if ([self.inspectorDelegate respondsToSelector:@selector(inspector:shouldCollapseView:withTitle:atIndex:)]) {
        return [self.inspectorDelegate inspector:self shouldCollapseView:item.view withTitle:item.title atIndex:[self.items indexOfObject:item]];
    }
    
    return YES;
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
    ZKInspectorItem *item = notification.userInfo[@"NSObject"];
    item.expanded = NO;
    
    if ([self.inspectorDelegate respondsToSelector:@selector(inspector:didCollapseView:withTitle:atIndex:)]) {
        [self.inspectorDelegate inspector:self didCollapseView:item.view withTitle:item.title atIndex:[self.items indexOfObject:item]];
    }
    
}

@end

