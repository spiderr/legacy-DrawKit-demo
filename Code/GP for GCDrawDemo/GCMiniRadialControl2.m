//
//  GCMiniRadialControl2.m
//  panel
//
//  Created by Graham on Tue Apr 17 2007.
//  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
//

#include <tgmath.h>
#import "GCMiniRadialControl2.h"

#import "NSBezierPath+GCAdditions.h"
#import <DKDrawKit/LogEvent.h>
#import "GCMiniControlCluster.h"

@implementation GCMiniRadialControl2
#pragma mark As a GCMiniRadialControl2
- (void)setCentre:(NSPoint)p
{
	if (!NSEqualPoints(p, mCentre)) {
		[self notifyDelegateWillChange:nil];
		mCentre = p;
		[self notifyDelegateDidChange:nil];
		[self setNeedsDisplay];
	}
}

@synthesize centre = mCentre;

#pragma mark -
- (void)setRadius:(CGFloat)radius
{
	if (radius != mRadius) {
		//	LogEvent_(kStateEvent, @"setting radius = %f", radius );

		[self notifyDelegateWillChange:nil];
		mRadius = radius;
		[self notifyDelegateDidChange:nil];
		[self setNeedsDisplay];

		if (!mIrisDilating) {
			// set tab angle to analogue of radius

			CGFloat ta = (radius / (M_PI * self.maxValue)) - (M_PI_4);
			self.tabAngle = ta;
		}
	}
}

@synthesize radius = mRadius;

#pragma mark -
- (void)setRingRadius:(CGFloat)radius
{
	mRingRadius = radius;
	[self invalidatePathCache];
}

- (CGFloat)ringRadius
{
	return mRingRadius * mRingScale;
}

- (void)setRingRadiusScale:(CGFloat)rsc
{
	mRingScale = rsc;
}

#pragma mark -
- (void)setTabColor:(NSColor *)colour
{
	mTabColour = colour;
	[self setNeedsDisplay];
}

- (NSColor *)tabColor
{
	return [mTabColour colorWithAlphaComponent:self.cluster.alpha * 1.0];
}

#pragma mark -
- (void)setTabAngle:(CGFloat)ta
{
	// tab angle is limited to +/- 45° around zero

	if (mIrisDilating)
		return;

	const CGFloat fortyfive = M_PI_4;

	if (ta < -fortyfive)
		ta = -fortyfive;

	if (ta > fortyfive)
		ta = fortyfive;

	if (ta != mTabAngle) {
		mTabAngle = ta;
		[self setNeedsDisplay];

		// tab angle sets the radius of the controlled gradient

		CGFloat r = (ta + fortyfive) * M_PI * self.maxValue;

		mIrisDilating = YES;
		self.radius = r;
		mIrisDilating = NO;
	}
}

- (CGFloat)tabAngle
{
	return mTabAngle;
}

#pragma mark -
- (NSBezierPath *)irisPath
{
	if (mIrisPath == nil) {
		CGFloat width = MAX(8, [self ringRadius] / 3.5);

		NSSize tabs = NSMakeSize(width * 1.5, width * 1.5);

		mIrisPath = [NSBezierPath bezierPathWithIrisRingWithRadius:self.ringRadius
															 width:width
														   tabSize:tabs];
	}

	NSAffineTransform *tfm = [NSAffineTransform transform];
	[tfm rotateByRadians:self.tabAngle];

	NSAffineTransform *t2 = [NSAffineTransform transform];
	[t2 translateXBy:self.centre.x yBy:self.centre.y];
	[tfm appendTransform:t2];

	return [tfm transformBezierPath:mIrisPath];
}

- (NSBezierPath *)tabPath
{
	if (mTabPath == nil) {
		CGFloat width = MAX(8, [self ringRadius] / 3.5) + 5;

		NSSize tabs = NSMakeSize(width * 0.67, width * 0.67);

		mTabPath = [NSBezierPath bezierPathWithIrisTabWithRadius:self.ringRadius
														   width:width
														 tabSize:tabs];
	}

	NSAffineTransform *tfm = [NSAffineTransform transform];
	[tfm rotateByRadians:self.tabAngle];

	NSAffineTransform *t2 = [NSAffineTransform transform];
	[t2 translateXBy:self.centre.x yBy:self.centre.y];
	[tfm appendTransform:t2];

	return [tfm transformBezierPath:mTabPath];
}

- (void)invalidatePathCache
{
	mTabPath = nil;
	mHitTabPath = nil;
	mIrisPath = nil;
}

#pragma mark -
// The hitTabPath is NEVER DRAWN. Its just a bit bigger to make sure
// it includes the "rim" around the gradient swatch so we don't initiate
// a drag from the tab

- (NSBezierPath *)hitTabPath
{
	if (mHitTabPath == nil) {
		CGFloat width = MAX(8, [self ringRadius] / 3.5);

		NSSize tabs = NSMakeSize(width * 1.5, width * 1.5);

		mHitTabPath = [NSBezierPath bezierPathWithIrisTabWithRadius:self.ringRadius
															  width:width
															tabSize:tabs];
	}

	NSAffineTransform *tfm = [NSAffineTransform transform];
	[tfm rotateByRadians:self.tabAngle];

	NSAffineTransform *t2 = [NSAffineTransform transform];
	[t2 translateXBy:self.centre.x yBy:self.centre.y];
	[tfm appendTransform:t2];

	return [tfm transformBezierPath:mHitTabPath];
}

- (NSPoint)trackPointForAngle:(CGFloat)degrees
{
	// returns a point on the ring radius at <degrees> angle.

	NSPoint p;
	CGFloat a;

	a = (degrees * M_PI) / 180.0;

	p.x = self.centre.x + (cos(a) * self.ringRadius);
	p.y = self.centre.y + (sin(a) * self.ringRadius);

	return p;
}

#pragma mark -
#pragma mark As a GCMiniControl
- (void)draw
{
	NSBezierPath *iris = self.irisPath;

	[[NSGraphicsContext currentContext] saveGraphicsState];

	[self applyShadow];
	[[self themeColour:kDKMiniControlThemeIris] set];
	[iris fill];

	// draw range track:
	/*
	[iris removeAllPoints];
	[iris appendBezierPathWithArcWithCenter:[self centre] radius:[self ringRadius] startAngle:-45 endAngle:45];
	[[self themeColour:kDKMiniControlThemeSliderTrack] set];
	[iris setLineWidth:0.5];
	[iris stroke];
	
	[iris removeAllPoints];
	[iris appendBezierPathWithArcWithCenter:[self centre] radius:[self ringRadius] + 1.0 startAngle:-45 endAngle:45];
	[[self themeColour:kDKMiniControlThemeSliderTrkHilite] set];
	[iris stroke];
	*/
	// range dots:

	NSPoint p = [self trackPointForAngle:-45];
	NSRect dot = NSInsetRect(NSMakeRect(p.x, p.y, 0, 0), -2, -2);
	[iris removeAllPoints];
	[iris appendBezierPathWithOvalInRect:dot];
	p = [self trackPointForAngle:45];
	dot = NSInsetRect(NSMakeRect(p.x, p.y, 0, 0), -2, -2);

	[iris appendBezierPathWithOvalInRect:dot];
	[[self themeColour:kDKMiniControlThemeKnobInterior] set];

	[iris fill];
	[[NSGraphicsContext currentContext] restoreGraphicsState];

	// debug - draw hit tab path
	/*
	[[NSColor redColor] set];
	[[self hitTabPath] stroke];
*/

	// tab swatch:

	NSBezierPath *tab = self.tabPath;
	[[[NSColor lightGrayColor] colorWithAlphaComponent:self.cluster.alpha] set];
	tab.lineWidth = 1.0;
	[tab stroke];
	[self.tabColor set];
	[tab fill];
}

- (GCControlHitTest)hitTestPoint:(NSPoint)p
{
	if ([super hitTestPoint:p] == kDKMiniControlEntireControl) {
		// NOTE: use the hitTabPath which is bigger than the tabPath which is drawn
		NSBezierPath *tab = [self hitTabPath];

		if ([tab containsPoint:p])
			return kDKRadial2HitTab;

		NSBezierPath *iris = self.irisPath;

		if ([iris containsPoint:p])
			return kDKRadial2HitIris;
	}

	return kDKMiniControlNoPart;
}

- (instancetype)initWithBounds:(NSRect)rect inCluster:(GCMiniControlCluster *)clust
{
	self = [super initWithBounds:rect inCluster:clust];
	if (self != nil) {
		self.tabColor = [NSColor blackColor];
		NSAssert(mTabPath == nil, @"Expected init to zero");
		NSAssert(mHitTabPath == nil, @"Expected init to zero");
		NSAssert(mIrisPath == nil, @"Expected init to zero");
		mCentre = NSMakePoint(NSMidX(rect), NSMidY(rect));
		NSAssert(NSEqualSizes(mOffset, NSZeroSize), @"Expected init to zero");

		NSAssert(mRadius == 0.0, @"Expected init to zero");
		mRingRadius = 48;
		mTabAngle = -M_PI_4;
		mRingScale = 1.0;
		NSAssert(!mIrisDilating, @"Expected init to zero");
		mAutoFlip = YES;

		if (mTabColour == nil) {
			return nil;
		}

		mMaxValue = 60;
		[self setInfoWindowMode:kDKMiniControlInfoWindowFollowsMouse];
	}
	return self;
}

- (BOOL)mouseDownAt:(NSPoint)currentPoint inPart:(GCControlHitTest)part modifierFlags:(NSEventModifierFlags)flags
{
#pragma unused(flags)
	if (part == kDKRadial2HitIris) {
		mOffset.width = currentPoint.x - self.centre.x;
		mOffset.height = currentPoint.y - self.centre.y;
	} else if (part == kDKRadial2HitTab) {
		NSPoint p = self.tabPath.bounds.origin;
		[self setupInfoWindowAtPoint:p withValue:self.radius andFormat:@"0.0"];
	} else
		return NO;

	return YES;
}

- (BOOL)mouseDraggedAt:(NSPoint)currentPoint inPart:(GCControlHitTest)part modifierFlags:(NSEventModifierFlags)flags
{
#pragma unused(flags)
	if (part == kDKRadial2HitIris) {
		NSPoint cp;

		cp.x = currentPoint.x - mOffset.width;
		cp.y = currentPoint.y - mOffset.height;

		self.centre = cp;
	} else if (part == kDKRadial2HitTab) {
		CGFloat a = atan2(currentPoint.y - [self centre].y, currentPoint.x - [self centre].x);

		self.tabAngle = a;

		NSPoint p = self.tabPath.bounds.origin;
		[self updateInfoWindowAtPoint:p withValue:self.radius];
	}

	return YES;
}

- (void)setBounds:(NSRect)r
{
	super.bounds = r;
	CGFloat rr;

	rr = MIN(NSWidth(r), NSHeight(r)) / 6;

	self.ringRadius = rr;
}

#pragma mark -
#pragma mark As an NSObject
- (void)dealloc
{
	[self invalidatePathCache];
}

@end
