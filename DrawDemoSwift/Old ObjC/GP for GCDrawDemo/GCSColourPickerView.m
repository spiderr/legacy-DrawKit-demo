//
//  GCColourPickerView.m
//  gradientpanel
//
//  Created by Graham on Tue Mar 27 2007.
//  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
//

#include <tgmath.h>
#import "GCSColourPickerView.h"

#import <DKDrawKit/NSColor+DKAdditions.h>
#import <DKDrawKit/GCInfoFloater.h>
#import <DKDrawKit/LogEvent.h>

#define ROWS 16
#define COLS 16

@implementation GCSColourPickerView
#pragma mark As a GCColourPickerView
- (void)setMode:(DKSColourPickerMode)aMode
{
	if (aMode != mMode) {
		mMode = aMode;
		[self setNeedsDisplay:YES];
	}
}

- (DKSColourPickerMode)mode
{
	return mMode;
}

#pragma mark -
- (void)drawSwatches:(NSRect)rect
{
	NSRect br = self.bounds;
	NSInteger swx, swy;

	swx = br.size.width / COLS;
	swy = br.size.height / ROWS;

	NSRect swr = NSMakeRect(0, 0, swx - 1, swy - 1);
	NSInteger i, j;

	swr.origin.x = 1;
	swr.origin.y = 1;

	for (i = 0; i < ROWS; ++i) {
		for (j = 0; j < COLS; ++j) {
			if (NSIntersectsRect(swr, rect)) {
				[[self colorForSwatchX:j y:i] drawSwatchInRect:swr];

				if (j == mSel.x && i == mSel.y) {
					[[NSColor blackColor] set];
					NSFrameRectWithWidth(swr, 2.0);
				}
			}
			swr.origin.x += swx;
		}

		swr.origin.x -= swx * COLS;
		swr.origin.y += swy;
	}
}

- (void)drawSpectrum:(NSRect)rect
{
	static NSImage *specImage = nil;

	if (specImage == nil) {
		specImage = [[NSBundle bundleForClass:[self class]] imageForResource:@"NSColorWheelImage"];

		[specImage setFlipped:YES];
	}

	// clip to a circle fitting bounds

	[[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(self.bounds, 5, 5)] addClip];

	// composite image + brightness to view

	if (self.brightness < 1.0) {
		[[NSColor blackColor] set];
		NSRectFill(rect);
	}

	[NSGraphicsContext currentContext].imageInterpolation = NSImageInterpolationHigh;
	[specImage drawInRect:rect fromRect:rect operation:NSCompositeCopy fraction:self.brightness];

	// draw the current colour location

	NSRect mr = [self rectForSpectrumPoint:mSel];
	[[NSColor contrastingColor:[self color]] set];
	[NSBezierPath setDefaultLineWidth:1.0];
	[[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(mr, 0.5, 0.5)] stroke];
}

#pragma mark -
- (NSColor *)color
{
	if (self.mode == kDKSColourPickerModeSwatches) {
		if (mSel.x < 0 || mSel.x > (COLS - 1) || mSel.y < 0 || mSel.y > (ROWS - 1))
			return mNonSelectColour;
		else
			return [self colorForSwatchX:mSel.x y:mSel.y];
	} else
		return [self colorForSpectrumPoint:mSel];
}

- (NSColor *)colorForSpectrumPoint:(NSPoint)p
{
	// given a point p, this figures out the colour in the colourwheel at that point

	CGFloat hue, sat;
	CGFloat angle, radius, mr;
	NSRect br = NSInsetRect(self.bounds, 4, 4);
	NSPoint cp;

	cp.x = NSMidX(br);
	cp.y = NSMidY(br);
	mr = br.size.width / 2.0;

	radius = hypot(p.x - cp.x, p.y - cp.y);
	angle = atan2(p.y - cp.y, p.x - cp.x);

	if (angle < 0)
		angle = (2 * M_PI) + angle;

	// is the point within the colour wheel?

	if (radius > mr)
		return mNonSelectColour;

	// convert to hue, saturation and brightness

	hue = 1.0 - (angle / (2 * M_PI));
	sat = radius / mr;

	return [NSColor colorWithCalibratedHue:hue saturation:sat brightness:self.brightness alpha:1.0];
}

- (NSPoint)pointForSpectrumColor:(NSColor *)colour
{
	// given a colour, returns the point in the spectrum wheel where it will be found

	NSColor *rgb = [colour colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

	CGFloat hue = rgb.hueComponent;
	CGFloat sat = rgb.saturationComponent;
	CGFloat angle, mr;

	NSRect br = NSInsetRect(self.bounds, 4, 4);
	NSPoint cp, p;

	cp.x = NSMidX(br);
	cp.y = NSMidY(br);
	mr = br.size.width / 2.0;

	angle = (1.0 - hue) * 2 * M_PI;

	p.x = cp.x + (cos(angle) * sat * mr);
	p.y = cp.y + (sin(angle) * sat * mr);

	return p;
}

- (NSRect)rectForSpectrumPoint:(NSPoint)sp
{
	return NSInsetRect(NSMakeRect(sp.x, sp.y, 0, 0), -4, -4);
}

- (BOOL)pointIsInColourwheel:(NSPoint)p
{
	NSRect br = NSInsetRect(self.bounds, 4, 4);
	NSPoint cp;
	CGFloat mr, radius;

	cp.x = NSMidX(br);
	cp.y = NSMidY(br);
	mr = br.size.width / 2.0;

	radius = hypot(p.x - cp.x, p.y - cp.y);

	return (radius <= mr);
}

#pragma mark -
- (void)setBrightness:(CGFloat)brightness
{
	brightness = MIN(brightness, 1.0);
	brightness = MAX(brightness, 0.0);

	if (brightness != mBright) {
		mBright = brightness;
		[self setNeedsDisplay:YES];

		if (self.mode == kDKSColourPickerModeSpectrum)
			[self sendToTarget];
	}
}

- (CGFloat)brightness
{
	return mBright;
}

#pragma mark -
- (NSPoint)swatchAtPoint:(NSPoint)p
{
	// returns x and y coordinates of the swatch containing p

	NSRect br = self.bounds;
	NSPoint sp;

	if (NSPointInRect(p, br)) {
		sp.x = (int)(p.x * COLS / br.size.width);
		sp.y = (int)(p.y * ROWS / br.size.height);
	} else
		sp.x = sp.y = -1;

	return sp;
}

#define qUseSystemColours 1

- (NSColor *)colorForSwatchX:(NSInteger)x y:(NSInteger)y
{
	// given a swatch coordinate x, y, this returns the colour at that coordinate

	CGFloat indx = (y * COLS) + x;

#if qUseSystemColours
	static NSColorList *cList = nil;

	if (cList == nil) {
		///*
		NSEnumerator *iter = [[NSColorList availableColorLists] objectEnumerator];
		NSColorList *c;

		while ((c = [iter nextObject]) != nil)
			//	LogEvent_(kInfoEvent, @"%@", [c name]);
			//*/
			cList = [NSColorList colorListNamed:@"Web Safe Colors"]; //Web Safe Colors
		//	LogEvent_(kReactiveEvent, @"clist = %@; colours = %d", cList, [[cList allKeys] count] );
	}

	NSArray *keys = cList.allKeys;

	NSInteger i = (NSInteger)indx % keys.count;
	return [cList colorWithKey:keys[i]];

#else
	CGFloat r, g, b;

	if (indx < 216) {
		r = (indx / 36) / 6.0;
		g = fmod(indx / 6, 6) / 6.0;
		b = fmod(indx, 6) / 6.0;
	} else if (indx < 224) {
		// fixed colours RGBCMY etc

		switch ((int)indx - 216) {
			case 0:
				return [NSColor redColor];

			case 1:
				return [NSColor greenColor];

			case 2:
				return [NSColor blueColor];

			case 3:
				return [NSColor cyanColor];

			case 4:
				return [NSColor magentaColor];

			case 5:
				return [NSColor yellowColor];

			case 6:
				return [NSColor purpleColor];

			case 7:
				return [NSColor orangeColor];
		}
	} else {
		r = g = b = ((int)indx - 223) / 32.0;
	}

	//	LogEvent_(kReactiveEvent,  @"color %d: r - %1.1f, g - %1.1f, b - %1.1f", (int)indx, r, g, b );

	return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
#endif
}

- (NSRect)rectForSwatch:(NSPoint)sp
{
	if (self.mode == kDKSColourPickerModeSwatches) {
		NSRect br = self.bounds;
		NSInteger swx, swy;

		swx = br.size.width / COLS;
		swy = br.size.height / ROWS;

		NSRect swr = NSMakeRect(1, 1, swx, swy);

		return NSOffsetRect(swr, sp.x * swx, sp.y * swy);
	} else
		return [self rectForSpectrumPoint:sp];
}

- (void)updateInfoAtPoint:(NSPoint)p
{
	if (!NSEqualPoints(NSMakePoint(-1, -1), p))
		[mInfoWin positionNearPoint:p inView:self];

	NSString *cf = [self color].hexString;
	[mInfoWin setStringValue:cf];
}

#pragma mark -
- (void)sendToTarget
{
	[NSApp sendAction:mSelector to:mTargetRef from:self];
}

#pragma mark -
- (void)setTarget:(id)target
{
	mTargetRef = target;
}

- (void)setAction:(SEL)selector
{
	mSelector = selector;
}

#pragma mark -
- (void)setColorForUndefinedSelection:(NSColor *)colour
{
	// set a colour to be returned when the selection doesn't resolve

	mNonSelectColour = colour;

	// set brightness to the colours brightness

	self.brightness = [colour colorUsingColorSpaceName:NSCalibratedRGBColorSpace].brightnessComponent;
}

- (void)setShowsInfo:(BOOL)si
{
	mShowsInfo = si;
}

#pragma mark -
#pragma mark As an NSView
- (void)drawRect:(NSRect)rect
{
	if (self.mode == kDKSColourPickerModeSwatches)
		[self drawSwatches:rect];
	else
		[self drawSpectrum:rect];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	if (theEvent.modifierFlags & NSAlternateKeyMask)
		self.mode = kDKSColourPickerModeSwatches;
	else
		self.mode = kDKSColourPickerModeSpectrum;
}

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self != nil) {
		[self setColorForUndefinedSelection:[NSColor grayColor]];
		mInfoWin = [GCInfoFloater infoFloater];
		NSAssert(mTargetRef == nil, @"Expected init to zero");
		mMode = kDKSColourPickerModeSpectrum;
		mSel = NSMakePoint(-1, -1);
		NSAssert(mSelector == nil, @"Expected init to zero");
		mBright = 1.0;
		mShowsInfo = YES;

		if (mNonSelectColour == nil || mInfoWin == nil) {
			return nil;
		}
	}
	if (self != nil) {
		[mInfoWin setWindowOffset:NSZeroSize];
	}
	return self;
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)mouseDown:(NSEvent *)event
{
	if (mShowsInfo) {
		NSInteger wn = self.window.windowNumber;

		[mInfoWin orderWindow:NSWindowAbove relativeTo:wn];
		[self updateInfoAtPoint:NSZeroPoint];
	}

	[self mouseDragged:event];
}

- (void)mouseDragged:(NSEvent *)event
{
	NSPoint s, p = [self convertPoint:event.locationInWindow fromView:nil];

	if (self.mode == kDKSColourPickerModeSwatches)
		s = [self swatchAtPoint:p];
	else
		s = p;

	if (!NSEqualPoints(mSel, s)) {
		[self setNeedsDisplayInRect:[self rectForSwatch:mSel]];
		mSel = s;
		[self setNeedsDisplayInRect:[self rectForSwatch:mSel]];
		[self sendToTarget];

		// in colourwheel mode, if sel is outside the wheel, set it to the undefined colour position

		if (self.mode == kDKSColourPickerModeSpectrum && ![self pointIsInColourwheel:p]) {
			mSel = [self pointForSpectrumColor:mNonSelectColour];
			self.brightness = mNonSelectColour.brightnessComponent;
			[self setNeedsDisplayInRect:[self rectForSwatch:mSel]];
		}
	}

	// update info window

	if (mShowsInfo)
		[self updateInfoAtPoint:NSMakePoint(-1, -1)];
}

- (void)mouseUp:(NSEvent *)event
{
#pragma unused(event)
	[mInfoWin orderOut:self];
}

- (void)viewDidMoveToWindow
{
	NSWindow *win = self.window;
	if (win == nil)
		[mInfoWin orderOut:nil];
}

#pragma mark -
#pragma mark As an NSResponder
- (void)scrollWheel:(NSEvent *)event
{
	if (self.mode == kDKSColourPickerModeSpectrum) {
		CGFloat deltay = event.deltaY / 150.0;
		self.brightness = self.brightness - deltay;
		[self updateInfoAtPoint:NSMakePoint(-1, -1)];
	}
}

#pragma mark -
#pragma mark As an NSObject

@end
