///**********************************************************************************************************************************
///  GCDashEditor.m
///  GCDrawKit
///
///  Created by graham on 18/05/2007.
///  Released under the Creative Commons license 2007 Apptree.net.
///
///
///  This work is licensed under the Creative Commons Attribution-ShareAlike 2.5 License.
///  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/2.5/ or send a letter to
///  Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
///
///**********************************************************************************************************************************

#import "GCDashEditor.h"
#import "GCDashEditView.h"

#import <DKDrawKit/DKStrokeDash.h>

@interface NSObject (SDEMethod)
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

@end

@implementation GCDashEditor
#pragma mark As a GCDashEditor
- (void)openDashEditorInParentWindow:(NSWindow *)pw modalDelegate:(id)del
{
	if ([self dash] == nil)
		[self setDash:[DKStrokeDash defaultDash]];

	mDelegateRef = del;
	[NSApp beginSheet:[self window] modalForWindow:pw modalDelegate:del didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:(__bridge void *_Null_unspecified)(self)];
	[self notifyDelegate];
}

- (void)updateForDash
{
	// set UI to match current dash

	[mDashPreviewEditView setDash:[self dash]];
	[self setDashCount:[[self dash] count]];
	[mDashScaleCheckbox setIntValue:[[self dash] scalesToLineWidth]];
	[mPhaseSlider setFloatValue:[[self dash] phase]];
}

- (void)setDash:(DKStrokeDash *)dash
{
	mDash = dash;

	[self updateForDash];
}

@synthesize dash = mDash;

#pragma mark -
- (void)setLineWidth:(CGFloat)width
{
	[mDashPreviewEditView setLineWidth:width];
}

- (CGFloat)lineWidth
{
	return mDashPreviewEditView.lineWidth;
}

- (void)setLineCapStyle:(NSLineCapStyle)lcs
{
	[mDashPreviewEditView setLineCapStyle:lcs];
}

- (NSLineCapStyle)lineCapStyle
{
	return mDashPreviewEditView.lineCapStyle;
}

- (void)setLineJoinStyle:(NSLineJoinStyle)ljs
{
	[mDashPreviewEditView setLineJoinStyle:ljs];
}

- (NSLineJoinStyle)lineJoinStyle
{
	return mDashPreviewEditView.lineJoinStyle;
}

- (void)setLineColour:(NSColor *)colour
{
	[mDashPreviewEditView setLineColour:colour];
}

- (NSColor *)lineColour
{
	return mDashPreviewEditView.lineColour;
}

#pragma mark -
- (void)setDashCount:(NSInteger)c
{
	int i;

	CGFloat d[8] = {1, 1, 1, 1, 1, 1, 1, 1};
	NSInteger count;

	[[self dash] getDashPattern:d count:&count];

	if (count != c) {
		[[self dash] setDashPattern:d count:c];
		count = c;
	}

	for (i = 0; i < 8; ++i) {
		if (i < count)
			[mEF[i] setFloatValue:d[i]];
		else
			[mEF[i] setStringValue:@""];

		[mEF[i] setEnabled:(i < count)];
	}

	[mDashCountButtonMatrix selectCellAtRow:0 column:(c - 1) / 2];
	[mPhaseSlider setMaxValue:[[self dash] length]];
}

- (NSInteger)dashCount
{
	NSInteger count;
	CGFloat d[8] = {1, 1, 1, 1, 1, 1, 1, 1};

	[[self dash] getDashPattern:d count:&count];

	return count;
}

- (void)notifyDelegate
{
	if ([mPreviewCheckbox intValue]) {
		if (mDelegateRef && [mDelegateRef respondsToSelector:@selector(dashDidChange:)])
			[mDelegateRef dashDidChange:self];
	}
}

#pragma mark -
- (IBAction)ok:(id)sender
{
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window] returnCode:NSOKButton];
}

- (IBAction)cancel:(id)sender
{
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window] returnCode:NSCancelButton];
}

- (IBAction)dashValueAction:(id)sender
{
#pragma unused(sender)
	CGFloat d[8];
	NSInteger i, c;

	c = [[self dash] count];

	for (i = 0; i < c; ++i)
		d[i] = [mEF[i] floatValue];

	[[self dash] setDashPattern:d count:c];
	[self notifyDelegate];
	[mPhaseSlider setMaxValue:[[self dash] length]];
	[mDashPreviewEditView setNeedsDisplay:YES];
}

- (IBAction)dashScaleCheckboxAction:(id)sender
{
	[[self dash] setScalesToLineWidth:[sender intValue]];
	[self notifyDelegate];
	[mDashPreviewEditView setNeedsDisplay:YES];
}

- (IBAction)dashCountMatrixAction:(id)sender
{
	NSInteger count = ([sender selectedColumn] + 1) * 2;
	[self setDashCount:count];
	[self notifyDelegate];
	[mDashPreviewEditView setNeedsDisplay:YES];
}

- (IBAction)dashPhaseSliderAction:(id)sender
{
	[[self dash] setPhase:[sender floatValue]];
	[self notifyDelegate];
	[mDashPreviewEditView setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark As a GCDashEditView delegate
- (void)dashDidChange:(id)sender
{
#pragma unused(sender)
	[self setDashCount:[[self dash] count]];
	[self notifyDelegate];
}

#pragma mark -
#pragma mark As part of NSNibAwaking  Protocol
- (void)awakeFromNib
{
	[super awakeFromNib];
	// copy the text fields to an array so we can access them from a loop

	mEF[0] = mDashMarkTextField1;
	mEF[1] = mDashSpaceTextField1;
	mEF[2] = mDashMarkTextField2;
	mEF[3] = mDashSpaceTextField2;
	mEF[4] = mDashMarkTextField3;
	mEF[5] = mDashSpaceTextField3;
	mEF[6] = mDashMarkTextField4;
	mEF[7] = mDashSpaceTextField4;

	[mPreviewCheckbox setIntValue:1];
	[mPhaseSlider setHidden:YES];
	[mDashPreviewEditView setDelegate:self];
	[self updateForDash];
}

@end
