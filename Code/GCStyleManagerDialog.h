/* GCStyleManagerDialog */

#import <Cocoa/Cocoa.h>


@class DKStyleRegistry, DKStyle;
@class GCBasicDialogController;
@class GCTableView;

@interface GCStyleManagerDialog : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet NSButton *mAddCategoryButton;
    IBOutlet NSButton *mDeleteCategoryButton;
    IBOutlet GCTableView *mStyleCategoryList;
    IBOutlet NSMatrix *mStyleIconMatrix;
    IBOutlet NSTextField *mStyleNameTextField;
	IBOutlet NSImageView *mPreviewImageWell;
	IBOutlet NSTabView *mStyleListTabView;
	IBOutlet NSTableView *mStyleBrowserList;
	IBOutlet NSButton *mDeleteStyleButton;
	IBOutlet GCBasicDialogController *mKeyChangeDialogController;
	
	DKStyle* mSelectedStyle;
	NSString* mSelectedCategory;
}
- (IBAction)	addCategoryAction:(id)sender;
- (IBAction)	deleteCategoryAction:(id)sender;
- (IBAction)	styleIconMatrixAction:(id)sender;
- (IBAction)	styleKeyChangeAction:(id)sender;
- (IBAction)	styleDeleteAction:(id) sender;
- (IBAction)	registryResetAction:(id) sender;
- (IBAction)	saveStylesToFileAction:(id) sender;
- (IBAction)	loadStylesFromFileAction:(id) sender;

- (DKStyleRegistry*)	styles;
- (void)				populateMatrixWithStyleInCategory:(NSString*) cat;
- (void)				updateUIForStyle:(DKStyle*) style;
- (void)				updateUIForCategory:(NSString*) category;

- (void)		sheetDidEnd:(NSWindow*) sheet returnCode:(NSInteger) returnCode  contextInfo:(void*) contextInfo;
- (void)		alertDidEnd:(NSAlert*) alert returnCode:(NSInteger) returnCode contextInfo:(void*) contextInfo;

@end
