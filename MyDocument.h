/*
 This file is part of TextForge.
 
 TextForge is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 TextForge is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with TextForge; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 
 Copyright (c) 2003-2004 Trance Software.
 */

#import <Cocoa/Cocoa.h>


@class tfTextView;
@interface MyDocument : NSDocument {
  // For main document window
  IBOutlet NSWindow *docWindow;
  IBOutlet NSScrollView *scrollView;
  IBOutlet NSTextField *lineNumberTextField;
  IBOutlet NSTextField *positionTextField;
  // For "Convert Tabs" sheet
  IBOutlet NSPanel *tabConvertPanel;
  IBOutlet NSButton *tabConvertButton;
  IBOutlet NSButton *tabConvertSelectionOnlyButton;
  IBOutlet NSButton *tabConvertCancelButton;
  IBOutlet NSTextField *tabConvertTextField;
  // For "Go To Line" sheet
  IBOutlet NSPanel *goToLinePanel;
  IBOutlet NSButton *goToLineOKButton;
  IBOutlet NSButton *goToLineCancelButton;
  IBOutlet NSTextField *goToLineTextField;
  // For "Change Case" sheet
  IBOutlet NSPanel *changeCasePanel;
  IBOutlet NSButton *changeCaseOKButton;
  IBOutlet NSButton *changeCaseCancelButton;
  IBOutlet NSButton *changeCaseSelectionOnlyButton;
  IBOutlet NSMatrix *changeCaseMatrix;
  // For "Get Info" sheet
  IBOutlet NSPanel *getInfoPanel;
  IBOutlet NSTextField *getInfoPathField;
  IBOutlet NSButton *getInfoCloseButton;
  IBOutlet NSTextField *getInfoAAField; // first letter (A or B) is column
  IBOutlet NSTextField *getInfoABField; // second letter (A, B, or C) is row
  IBOutlet NSTextField *getInfoACField;
  IBOutlet NSTextField *getInfoBAField;
  IBOutlet NSTextField *getInfoBBField;
  IBOutlet NSTextField *getInfoBCField;
  @private
  BOOL wasOpened;
  int lineBreakType;
  NSStringEncoding fileEncoding;
  NSString *docString;
  tfTextView *textView;
  int lineCountNum;
}

-(id)init;
-(IBAction)encodingChanged:(id)sender;
-(IBAction)LBChanged:(id)sender;
-(IBAction)runTabConvertSheet:(id)sender;
-(IBAction)tabConvertSheetEnd:(id)sender;
-(IBAction)runGetInfoSheet:(id)sender;
-(IBAction)getInfoSheetEnd:(id)sender;
-(IBAction)runChangeCaseSheet:(id)sender;
-(IBAction)changeCaseSheetEnd:(id)sender;
-(IBAction)goToLineSheet:(id)sender;
-(IBAction)goToLineSheetEnd:(id)sender;
-(IBAction)toggleSoftWrap:(id)sender;
-(IBAction)insertDocument:(id)sender;
-(IBAction)insertMSWordDoc:(id)sender;
-(IBAction)insertPath:(id)sender;
-(IBAction)selectEntireLine:(id)sender;
-(IBAction)runInTerminal:(id)sender;
-(IBAction)previewInBrowser:(id)sender;
-(void)setFileName:(NSString *)fileName;
-(NSString *)windowNibName;
-(void)windowControllerDidLoadNib:(NSWindowController*)aController;
-(NSData *)dataRepresentationOfType:(NSString *)aType;
-(BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType;
-(void)textDidChange:(NSNotification *)aNotification;
-(NSWindow*)window;
-(BOOL)isWrapped;
-(NSDictionary *)fileAttributesToWriteToFile:(NSString *)fullDocumentPath ofType:(NSString *)documentTypeName saveOperation:(NSSaveOperationType)saveOperationType;
-(NSString*)getString;
-(void)setString:(NSString*)string;
-(void)selectText:(NSRange)range;
-(NSRange)getInsertionPointRange;
-(tfTextView*)getTextView;
-(void)openPanelForDIDidEnd:(NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo;
-(void)openPanelForPIDidEnd:(NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo;
-(void)windowDidResize:(NSNotification *)aNotification;
-(void)UndoManagerDidUndoOrRedo:(NSNotification *)aNotification;
-(BOOL)validateMenuItem:(NSMenuItem*)anItem;
-(IBAction)checkPerlSyntax:(id)sender;
-(void)textViewDidChangeSelection:(NSNotification*)aNotification;
-(void)changeDocEncoding:(NSStringEncoding)encoding;
-(NSStringEncoding)getEncoding;
-(BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString*)replacementString;

@end
