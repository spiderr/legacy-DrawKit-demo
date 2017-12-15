#import <Cocoa/Cocoa.h>

@interface GCSDrawDemoPrefsController : NSWindowController {
	IBOutlet NSButton *mQualityThrottlingCheckbox;
	IBOutlet NSButton *mUndoSelectionsCheckbox;
	IBOutlet NSButton *mStorageTypeCheckbox;
}

- (IBAction)qualityThrottlingAction:(id)sender;
- (IBAction)undoableSelectionAction:(id)sender;
- (IBAction)setStorageTypeAction:(id)sender;

@end
