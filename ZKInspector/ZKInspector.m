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
@import QuartzCore.CATransaction;

#define kDefaultHeaderHeight 24.0
const void *kRowViewContext;

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

- (void)viewDidMoveToWindow {
    [self addObserver:self forKeyPath:@"item" options:0 context:&kRowViewContext];
    [self addObserver:self forKeyPath:@"item.expanded" options:0 context:&kRowViewContext];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"item"];
    [self removeObserver:self forKeyPath:@"item.expanded"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &kRowViewContext) {
        [self setNeedsDisplay:YES];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    NSUInteger row = [self.outlineView rowForItem:self.item];
    if (!self.item.isExpanded) {
        [[NSColor lightGrayColor] set];
        NSRectFill(NSMakeRect(0, NSMaxY(self.bounds) - 2, self.bounds.size.width, 1));
        
        [[[NSColor whiteColor] colorWithAlphaComponent:0.3] set];
        NSRectFill(NSMakeRect(0, NSMaxY(self.bounds) - 1, self.bounds.size.width, 1));
    }
    
    if (row != 0) {
        [[NSColor lightGrayColor] set];
        NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));
        
        [[[NSColor whiteColor] colorWithAlphaComponent:0.3] set];
        NSRectFill(NSMakeRect(0, 1, self.bounds.size.width, 1));
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
        
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        self.cellView.translatesAutoresizingMaskIntoConstraints = NO;
        self.cellView.rowSizeStyle = NSTableViewRowSizeStyleLarge;
        
        NSView *wrap = [[NSView alloc] initWithFrame:self.cellView.bounds];
        wrap.translatesAutoresizingMaskIntoConstraints = NO;
        [wrap addSubview:textField];
        [self.cellView addSubview:wrap];
        self.cellView.textField = textField;
        
        NSDictionary *views = NSDictionaryOfVariableBindings(wrap, textField);
        [self.cellView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(8)-[wrap]|"
                                                                              options:0
                                                                              metrics:nil
                                                                                views:views]];
        [self.cellView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[wrap]|"
                                                                              options:0
                                                                              metrics:nil
                                                                                views:views]];
        [wrap addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textField]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:views]];
        [wrap addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textField]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:views]];
        [textField bind:NSValueBinding toObject:self withKeyPath:@"title" options:nil];
        self.titleRowView = [[ZKTitleRowView alloc] initWithFrame:NSZeroRect];
    }
    
    return self;
}

- (void)dealloc {
    [self.cellView.textField unbind:NSValueBinding];
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
- (void)_startObservingItem:(ZKInspectorItem *)item;
- (void)_stopObservingItem:(ZKInspectorItem *)item;
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
    self.outlineTableColumn.minWidth = 100;
    self.outlineTableColumn.maxWidth = FLT_MAX;
    self.outlineTableColumn.resizingMask = NSTableColumnAutoresizingMask;
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
    self.focusRingType = NSFocusRingTypeNone;
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    
    self.delegate = self;
    self.dataSource = self;
    [self reloadData];
}

- (BOOL)acceptsFirstResponder {
    return NO;
}

#pragma mark - Actions

- (void)addView:(NSView *)view withTitle:(NSString *)title expanded:(BOOL)expanded {
    [self insertView:view withTitle:title atIndex:self.items.count expanded:expanded];
}

- (void)insertView:(NSView *)view withTitle:(NSString *)title atIndex:(NSUInteger)index expanded:(BOOL)expanded {
    NSAssert([self _itemForTitle:title] == nil && [self _itemForView:view] == nil, @"Every view in ZKInspector must have a unique title and view (%@, %@)", title, view);
    
    ZKInspectorItem *item = [[ZKInspectorItem alloc] init];
    item.title = title;
    item.view = view;
    [self _startObservingItem:item];
    [self.items insertObject:item atIndex:index];
    
    [self beginUpdates];
    [self insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:nil withAnimation:NSTableViewAnimationSlideDown];
    if (expanded) {
        __weak ZKInspectorItem *weakItem = item;
        __weak ZKInspector *weakSelf = self;
        [CATransaction setCompletionBlock:^{
            [weakSelf _expandItem:weakItem];
        }];
    }
    [self endUpdates];
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
    [self _stopObservingItem:self.items[index]];
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

#pragma mark - Private

static void *ZKDirtyViewContext;

- (void)_startObservingItem:(ZKInspectorItem *)item {
    [item addObserver:self forKeyPath:@"view.frame"
              options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
              context:&ZKDirtyViewContext];
}

- (void)_stopObservingItem:(ZKInspectorItem *)item {
    [item removeObserver:self forKeyPath:@"view.frame" context:&ZKDirtyViewContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &ZKDirtyViewContext) {
        NSValue *oldFrame = change[NSKeyValueChangeOldKey];
        NSValue *newFrame = change[NSKeyValueChangeNewKey];
        
        if ([oldFrame isKindOfClass:[NSNull class]])
            oldFrame = nil;
        if ([newFrame isKindOfClass:[NSNull class]])
            newFrame = nil;
        
        NSRect oldRect = oldFrame.rectValue;
        NSRect newRect = newFrame.rectValue;
        
        if (oldRect.size.height != newRect.size.height) {
            // It would've been nice to get the animation that this provides, but the outline view seems to get the delta
            // for the previous and current heights and keeps setting the frame of the view which causes an infinite loop
//            [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[self rowForView:((ZKInspectorItem *)object).view]]];
            [self reloadItem:object reloadChildren:YES];
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (ZKInspectorItem *)_itemForView:(NSView *)view {
    return [[self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"view == %@", view]] firstObject];
}

- (ZKInspectorItem *)_itemForTitle:(NSString *)title {
    return [[self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"title == %@", title]] firstObject];
}

- (void)_expandItem:(ZKInspectorItem *)item {
    [self expandItem:item expandChildren:YES];
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

#pragma mark - Override

- (BOOL)validateProposedFirstResponder:(NSResponder *)responder forEvent:(NSEvent *)event {
    return YES;
}

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row {
    NSRect frame = [super frameOfCellAtColumn:column row:row];
    frame.size.width = self.bounds.size.width;
    return frame;
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

