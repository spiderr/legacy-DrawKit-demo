//
//  GCMiniSlider.m
//  panel
//
//  Created by Graham on Thu Apr 12 2007.
//  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
//

#import "GCMiniSlider.h"

#import "GCGradientPanel.h"
#import "NSBezierPath+GCAdditions.h"
#import "GCMiniControlCluster.h"

@implementation GCMiniSlider
#pragma mark As a GCMiniSlider
@synthesize showTickMarks = mShowTicks;
- (void)setShowTickMarks:(BOOL)ticks
{
	if (ticks != mShowTicks) {
		mShowTicks = ticks;
		[self setNeedsDisplay];
	}
}

#pragma mark -
- (NSRect)knobRect
{
	NSRect kr = NSInsetRect(self.bounds, kMiniSliderEndCapWidth, 1);

	CGFloat length = self.bounds.size.width - (kMiniSliderEndCapWidth * 2);

	kr.size = mKnobImage.size;
	kr.origin.x += (self.value * length) - (kr.size.width / 2.0);
	kr.origin.y = NSMidY(self.bounds) - (kr.size.height / 2.0);

	return kr;
}

#pragma mark -
#pragma mark As a GCMiniControl
- (void)draw
{
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundEndedRectInRect:self.bounds];

	[[NSGraphicsContext currentContext] saveGraphicsState];

	[self applyShadow];
	[[self themeColour:kDKMiniControlThemeBackground] set];
	[path fill];
	[[NSGraphicsContext currentContext] restoreGraphicsState];

	[[self themeColour:kDKMiniControlThemeSliderTrack] set];

	NSPoint sp, ep;

	sp.x = NSMinX(self.bounds) + kMiniSliderEndCapWidth;
	sp.y = NSMidY(self.bounds);
	ep.x = NSMaxX(self.bounds) - kMiniSliderEndCapWidth;
	ep.y = NSMidY(self.bounds);

	[NSBezierPath setDefaultLineWidth:0.5];
	[NSBezierPath strokeLineFromPoint:sp toPoint:ep];

	sp.y += 1.0;
	ep.y += 1.0;

	[[self themeColour:kDKMiniControlThemeSliderTrkHilite] set];
	[NSBezierPath strokeLineFromPoint:sp toPoint:ep];

	// position and draw the knob

	[mKnobImage drawInRect:[self knobRect] fromRect:NSZeroRect operation:NSCompositingOperationSourceAtop fraction:self.cluster.alpha];
}

- (GCControlHitTest)hitTestPoint:(NSPoint)p
{
	GCControlHitTest ph = [super hitTestPoint:p];

	if (ph == kDKMiniControlEntireControl) {
		if (NSPointInRect(p, [self knobRect]))
			ph = kDKMiniSliderKnob;
	}

	return ph;
}

- (instancetype)initWithBounds:(NSRect)rect inCluster:(GCMiniControlCluster *)clust
{
	self = [super initWithBounds:rect inCluster:clust];
	if (self != nil) {
		//mKnobImage = [[NSImage imageNamed:@"smallBlueKnob"] retain];

		mKnobImage = [NSImage imageNamed:@"smallBlueKnob"];

		NSAssert(!mShowTicks, @"Expected init to zero");

		if (mKnobImage == nil) {
			return nil;
		}
		//[mKnobImage setFlipped:YES];
	}
	return self;
}

- (BOOL)mouseDownAt:(NSPoint)startPoint inPart:(GCControlHitTest)part modifierFlags:(NSEventModifierFlags)flags
{
#pragma unused(flags)
	if (part == kDKMiniSliderKnob)
		[self setupInfoWindowAtPoint:startPoint withValue:self.value andFormat:nil];
	return (part == kDKMiniSliderKnob);
}

- (BOOL)mouseDraggedAt:(NSPoint)currentPoint inPart:(GCControlHitTest)part modifierFlags:(NSEventModifierFlags)flags
{
	// recalculate the value based on the position of the knob

	CGFloat val = (currentPoint.x - (NSMinX(self.bounds) + kMiniSliderEndCapWidth)) / (self.bounds.size.width - (kMiniSliderEndCapWidth * 2));

	[super mouseDraggedAt:currentPoint inPart:part modifierFlags:flags];

	[self setNeedsDisplayInRect:[self knobRect]];
	self.value = val;
	[self setNeedsDisplayInRect:[self knobRect]];

	return YES;
}

#pragma mark -
#pragma mark As an NSObject

@end
