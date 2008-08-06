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

#import "jaStringMethods.h"
#import "EncodingManager.h"
#import "MyDocumentController.h"
#import "Common.h"
#import "BrowserPanel.h"
#import "MyDocument.h"
#import "tfTextView.h"

#define __CONTENT_LENGTH [textView contentLength]

/*
 GENERAL NOTES
 
 - NibLoaded messages come after load data messages
 - Any changes made to the document should be registered with the undo manager
*/

@implementation MyDocument

/*
 INIT METHODS
*/

- (id)init {
  self = [super init];
  if (self) {
    // Add your subclass-specific initialization here.
    // If an error occurs here, send a [self release] message and return nil.
    wasOpened = FALSE;
    // Set file encoding to save encoding because if its new this will be the default
    fileEncoding = [PREFERENCES integerForKey:@"SaveEncoding"];
    // Set up line breaks
    lineBreakType = [PREFERENCES integerForKey:@"LineBreakFormat"];
    // Undo and redo fuck with the line counting - do a recount whenever that happens
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UndoManagerDidUndoOrRedo:) name:@"NSUndoManagerDidRedoChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UndoManagerDidUndoOrRedo:) name:@"NSUndoManagerDidUndoChangeNotification" object:nil];
  }
  return self;
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [textView release];
  [super dealloc];
}

- (void)windowControllerDidLoadNib:(NSWindowController*)aController {
  NSSize contentSize;
  NSRect tempFrameRect;
  NSRect tempContentRect;
  [super windowControllerDidLoadNib:aController];
  // Swap to custom NSTextView
  contentSize = [scrollView contentSize];
  textView = [[tfTextView alloc] initWithFrame:NSMakeRect(0,0,contentSize.width,contentSize.height) textContainer:[[scrollView documentView] textContainer]];
  [scrollView setDocumentView:textView];
  [textView release];
  [textView setDelegate:self];
  [textView setParentDocument:self];
  [textView setDrawsBackground:YES];
  [scrollView setDrawsBackground:NO];
  // Set up window size/position
  tempFrameRect = NSMakeRect([docWindow frame].origin.x, [docWindow frame].origin.y, [PREFERENCES floatForKey:@"DocWindowWidth"], [PREFERENCES floatForKey:@"DocWindowHeight"]);
  tempContentRect = [NSWindow contentRectForFrameRect:tempFrameRect styleMask:[docWindow styleMask]];
  [docWindow setFrameOrigin:NSMakePoint(tempFrameRect.origin.x, (tempFrameRect.origin.y + ([docWindow frame].size.height - tempFrameRect.size.height)))];
  [docWindow setContentSize:NSMakeSize(tempContentRect.size.width, tempContentRect.size.height)];
  // Set up window for content area transparency
  [docWindow setOpaque:NO];
  // Set up line counting
  lineCountNum = 1;
  // if document was opened
  if (wasOpened) {
    [textView setString:docString];
    [textView setSelectedRange:NSMakeRange(0,0)];
    lineBreakType = [jaStringMethods detectLBFormat:docString];
        // Don't allow editing if the file isn't writable
    [textView setEditable:[FILEMANAGER isWritableFileAtPath:[self fileName]]];
  }
  // Set up color scheme
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ColorsDidChangeNotification" object:self];
  // Honor default text wrapping pref - there is no need to explicitly order wrapping because its naturally that way
  if (![PREFERENCES boolForKey:@"SoftWrapDefault"]) {
    [textView noWrap];
  }
}

/*
 IBActions
*/

-(IBAction)encodingChanged:(id)sender {
  if (__CONTENT_LENGTH > 0) {
    [self updateChangeCount:NSChangeDone];
  }
}

-(IBAction)LBChanged:(id)sender {
  if ((__CONTENT_LENGTH > 0) && ([sender tag] != lineBreakType)) {
    [self updateChangeCount:NSChangeDone];
  }
  lineBreakType = [sender tag];
}

-(IBAction)runTabConvertSheet:(id)sender {
  [[sender title] isEqualToString:@"Entab..."] ? [tabConvertButton setTitle:@"Entab"] : [tabConvertButton setTitle:@"Detab"];
  [tabConvertSelectionOnlyButton setEnabled:([textView selectedRange].length > 0)];
  [NSApp beginSheet:tabConvertPanel modalForWindow:docWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(IBAction)tabConvertSheetEnd:(id)sender {
  [NSApp endSheet:tabConvertPanel];
  [tabConvertPanel orderOut:self];
  if (![[sender title] isEqualToString:@"Cancel"]) {
    int i;
    NSString *stringToReplace;
    NSString *replacementString;
    NSMutableString *spaceString = [[NSMutableString alloc] init];
    BOOL selectionOnly = ([tabConvertSelectionOnlyButton state] == NSOnState);
    unichar tabChar = 0x0009;
    NSString *tabString = [[NSString alloc] initWithCharacters:&tabChar length:1];
    // Set up spaces
    for (i = 0; i < [tabConvertTextField intValue]; i++) {
      [spaceString appendString:@" "];
    }
    // Set up based on entab or detab
    if ([[sender title] isEqualToString:@"Entab"]) {
      replacementString = tabString;
      stringToReplace = [NSString stringWithString:spaceString];
    }
    else {
      replacementString = [NSString stringWithString:spaceString];
      stringToReplace = tabString;
    }
    // Do conversion; Don't ignore case - it takes longer; beep if nothing happens
    if ([textView replaceAll:stringToReplace with:replacementString inSelectionOnly:selectionOnly ignoreCase:NO] < 1) {
      NSBeep();
    }
    // Clean up
    [spaceString release];
    [tabString release];
  }
}

-(IBAction)runGetInfoSheet:(id)sender {
  NSRange cursorRange = [textView selectedRange];
  NSRange docRange = NSMakeRange(0, __CONTENT_LENGTH);
  NSString *pathName = [self fileName];
  (pathName == nil) ? [getInfoPathField setStringValue:@"Document Not Saved"] : [getInfoPathField setStringValue:pathName];
    // Set up first column (selection)
  if (cursorRange.length > 0) {
    [getInfoAAField setIntValue:[textView getWordCountInRange:cursorRange]];
    [getInfoABField setIntValue:[textView getCharacterCountInRange:cursorRange]];
    [getInfoACField setIntValue:[textView getLineCountInRange:cursorRange]];
  }
  else {
    [getInfoAAField setStringValue:@"N/A"];
    [getInfoABField setStringValue:@"N/A"];
    [getInfoACField setStringValue:@"N/A"];
  }
  // Set up second column (document)
  [getInfoBAField setIntValue:[textView getWordCountInRange:docRange]];
  [getInfoBBField setIntValue:[textView getCharacterCountInRange:docRange]];
  [getInfoBCField setIntValue:[textView getLineCountInRange:docRange]];
  [NSApp beginSheet:getInfoPanel modalForWindow:docWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(IBAction)getInfoSheetEnd:(id)sender {
  [NSApp endSheet:getInfoPanel];
  [getInfoPanel orderOut:self];
}

- (IBAction)runChangeCaseSheet:(id)sender {
  [changeCaseSelectionOnlyButton setEnabled:([textView selectedRange].length > 0)];
  [NSApp beginSheet:changeCasePanel modalForWindow:docWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(IBAction)changeCaseSheetEnd:(id)sender {
  [NSApp endSheet:changeCasePanel];
  [changeCasePanel orderOut:self];
  if (![[sender title] isEqualToString:@"Cancel"]) {
    BOOL selectionOnly = ([changeCaseSelectionOnlyButton state] == NSOnState);
    NSString *textString = [textView string];
    NSRange replaceRange = (selectionOnly ? [textView selectedRange] : NSMakeRange(0,[textString length]));
    NSString *replacementString = [textString substringWithRange:replaceRange];
    if ([[changeCaseMatrix cellAtRow:0 column:0] state] == NSOnState) { // Upper
      replacementString = [replacementString uppercaseString];
    }
    else if ([[changeCaseMatrix cellAtRow:1 column:0] state] == NSOnState) { // Lower
      replacementString = [replacementString lowercaseString];
    }
    else { // capitalize words
      replacementString = [replacementString capitalizedString];
    }
    [textView replaceInRange:replaceRange with:replacementString];
  }
}

-(IBAction)goToLineSheet:(id)sender {
  [NSApp beginSheet:goToLinePanel modalForWindow:docWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(IBAction)goToLineSheetEnd:(id)sender {
  [NSApp endSheet:goToLinePanel];
  [goToLinePanel orderOut:self];
  if (![[sender title] isEqualToString:@"Cancel"]) {
    ([goToLineTextField intValue] < 1) ? NSBeep() : [textView setCursorToLine:[goToLineTextField intValue]];
  }
  [[MyDocumentController sharedInstance] jumpToSelection:self];
}

-(IBAction)toggleSoftWrap:(id)sender {
  ([sender state] == NSOnState) ? [sender setState:NSOffState] : [sender setState:NSOnState];
  ([sender state] == NSOnState) ? [textView wrap] : [textView noWrap];
}

-(IBAction)insertDocument:(id)sender {
  NSOpenPanel *op = [NSOpenPanel openPanel];
  [op setCanChooseFiles:YES];
  [op setAccessoryView:[[EncodingManager sharedInstance] getOASAView:TRUE]];
  [op setCanChooseDirectories:NO];
  [op setResolvesAliases:YES];
  [op setAllowsMultipleSelection:NO];
  [op beginSheetForDirectory:NSHomeDirectory() file:nil types:nil modalForWindow:docWindow modalDelegate:self didEndSelector:@selector(openPanelForDIDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)insertMSWordDoc:(id)sender {
  NSOpenPanel *op = [NSOpenPanel openPanel];
  [op setCanChooseFiles:YES];
  [op setCanChooseDirectories:NO];
  [op setResolvesAliases:YES];
  [op setAllowsMultipleSelection:NO];
  [op beginSheetForDirectory:NSHomeDirectory() file:nil types:[NSArray arrayWithObject:@"doc"] modalForWindow:docWindow modalDelegate:self didEndSelector:@selector(openPanelForMSDIDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)insertPath:(id)sender {
  NSOpenPanel *op = [NSOpenPanel openPanel];
  [op setCanChooseFiles:YES];
  [op setCanChooseDirectories:YES];
  [op setResolvesAliases:NO];
  [op setAllowsMultipleSelection:NO];
  [op beginSheetForDirectory:NSHomeDirectory() file:nil types:nil modalForWindow:docWindow modalDelegate:self didEndSelector:@selector(openPanelForPIDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)selectEntireLine:(id)sender {
  [textView setSelectedRange:[[textView string] lineRangeForRange:[textView selectedRange]]];
}

-(IBAction)runInTerminal:(id)sender {
  if (([self fileName] == nil) || [docWindow isDocumentEdited]) {
    NSBeginAlertSheet(@"Run in Terminal Error", @"Cancel", nil, nil, docWindow, nil, nil, nil, nil, @"You must save your document before running it in Terminal.");
  }
  else {
    NSString *temp = [[textView textStorage] string];
    NSRange firstLine = [temp lineRangeForRange:NSMakeRange(0,0)];
    if ((firstLine.length > 3) && ([temp characterAtIndex:0] == '#') && ([temp characterAtIndex:1] == '!') && ([temp characterAtIndex:2] == '/')) {
      // Put together term file, save it to temp dir, then run it
      NSMutableString *termFile = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"template" ofType:@"term" inDirectory:nil]];
      NSString *termCommand = [NSString stringWithFormat:@"%@ \"%@\"", [temp substringWithRange:NSMakeRange((firstLine.location + 2), (firstLine.length - 3))], [self fileName]];
      [termFile replaceOccurrencesOfString:@"PUT_COMMANDS_HERE" withString:termCommand options:0 range:NSMakeRange(0, [termFile length])];
      [termFile writeToFile:@"/tmp/textforge.term" atomically:YES];
      [[NSWorkspace sharedWorkspace] openTempFile:@"/tmp/textforge.term"];
    }
    else {
      NSBeep();
      NSBeginAlertSheet(@"Run in Terminal Error", @"OK", nil, nil, docWindow, nil, nil, nil, nil, @"Your document does not contain a valid shebang (\"#!/\") line!");
    }
  }
}

- (void)setFileName:(NSString *)fileName {
  [super setFileName:fileName];
}

/*
 REGULAR METHODS
*/

- (NSString *)windowNibName {
  // If you need to use a subclass of NSWindowController or if your document supports multiple
  // NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
  return @"Document";
}

- (NSData *)dataRepresentationOfType:(NSString *)aType {
    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
  NSMutableString *string = [[NSMutableString alloc] init];
  [string setString:[textView string]];
  // Convert to the correct line break type
  if (lineBreakType == 3) {
    [jaStringMethods convertStringToDOS:string];
  }
  else if (lineBreakType == 2) {
    [jaStringMethods convertStringToMac:string];
  }
  else { // UNIX (1)
    [jaStringMethods convertStringToUnix:string];
  }
  // Saved: window contents aren't dirty
  [docWindow setDocumentEdited:NO];
  if (fileEncoding == NoStringEncoding) {
    return [string dataUsingEncoding:[NSString defaultCStringEncoding] allowLossyConversion:YES];
  }
  else {
    return [string dataUsingEncoding:fileEncoding allowLossyConversion:YES];
  }
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType {
  fileEncoding = [PREFERENCES integerForKey:@"OpenEncoding"];
  wasOpened = TRUE;
  if (fileEncoding == NoStringEncoding) {
    docString = [NSString stringWithContentsOfFile:fileName];
  }
  else {
    NSData *tempData = [NSData dataWithContentsOfFile:fileName];
    if (tempData) {
      docString = [[[NSString alloc] initWithData:tempData encoding:fileEncoding] autorelease];
    }
  }
  return docString ? YES : NO;
}

- (void)textDidChange:(NSNotification *)aNotification {
  [self updateChangeCount:NSChangeDone];
}

- (NSWindow*)window {
  return docWindow;
}

-(BOOL)isWrapped {
  return ![scrollView hasHorizontalScroller];
}

- (NSDictionary *)fileAttributesToWriteToFile:(NSString *)fullDocumentPath ofType:(NSString *)documentTypeName saveOperation:(NSSaveOperationType)saveOperationType {
  NSNumber *typeCode, *creatorCode;
  NSMutableDictionary *newAttributes;
  typeCode = creatorCode = nil;
  // First, set creatorCode to the HFS creator code for the application
  creatorCode = [NSNumber numberWithUnsignedLong:NSHFSTypeCodeFromFileType(@"'tfrg'")];
  typeCode = [NSNumber numberWithUnsignedLong:NSHFSTypeCodeFromFileType(@"'****'")];
  // If neither type nor creator code exist, use the default implementation.
  if (!(typeCode || creatorCode)) {
    return [super fileAttributesToWriteToFile:fullDocumentPath ofType:documentTypeName saveOperation:saveOperationType];
  }
  // Otherwise, add the type and/or creator to the dictionary.
  newAttributes = [NSMutableDictionary dictionaryWithDictionary:[super fileAttributesToWriteToFile:fullDocumentPath ofType:documentTypeName saveOperation:saveOperationType]];
  if (typeCode) {
    [newAttributes setObject:typeCode forKey:NSFileHFSTypeCode];
  }
  if (creatorCode) {
    [newAttributes setObject:creatorCode forKey:NSFileHFSCreatorCode];
  }
  return newAttributes;
}

-(NSString*)getString {
  return [textView string];
}

-(void)setString:(NSString*)string {
  [textView setString:string];
}

-(void)selectText:(NSRange)range {
  [textView setSelectedRange:range];
}

-(NSRange)getInsertionPointRange {
  return [textView selectedRange];
}

-(tfTextView*)getTextView {
  return textView;
}

/*
 DELEGATE METHODS
 */

// THIS IS FOR INSERT DOCUMENT SHEET
- (void)openPanelForDIDidEnd:(NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo {
  if (returnCode == NSOKButton) {
    NSString *filePath = [[sheet filenames] objectAtIndex:0];
    NSString *newDocString;
    // Dig into the accessory view hierarchy to grab the tag of the selected item from the encoding popup
    int tag = [[((NSPopUpButton*)[[[[[sheet accessoryView] subviews] objectAtIndex:0] subviews] objectAtIndex:0]) selectedItem] tag];
    if (tag == -1) {
      newDocString = [NSString stringWithContentsOfFile:filePath];
    }
    else {
      NSData *tempData = [NSData dataWithContentsOfFile:filePath];
      newDocString = [[[NSString alloc] initWithData:tempData encoding:tag] autorelease];
    }
    [textView insertText:newDocString];
  }
}

// THIS IS FOR INSERT MS WORD DOCUMENT SHEET
- (void)openPanelForMSDIDidEnd:(NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo {
  if (returnCode == NSOKButton) {
    NSString *filePath = [[[sheet filenames] objectAtIndex:0] stringByStandardizingPath];
    NSString *executablePath = [[NSBundle mainBundle] pathForResource:@"antiword" ofType:nil inDirectory:@"antiword"];
    NSTask *antiword = [[NSTask alloc] init];
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *handle = [pipe fileHandleForReading];
    NSString *output;
    [antiword setLaunchPath:executablePath];
    // output data in UTF-8 every time
    [antiword setArguments:[NSArray arrayWithObjects:@"-m", @"UTF-8.txt", filePath, nil]];
    [antiword setStandardOutput:pipe];
    [antiword setStandardError:pipe];
    [antiword setCurrentDirectoryPath:[[NSBundle mainBundle] pathForResource:@"antiword" ofType:nil]];
    [antiword launch];
    // we told antiword to output its data in UTF-8, so we need to read it that way
    output = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    [textView insertText:output];
    [antiword release];
    [output release];
  }
}

// THIS IS FOR INSERT PATH SHEET
- (void)openPanelForPIDidEnd:(NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo {
  if (returnCode == NSOKButton) {
    [textView insertText:[[sheet filenames] objectAtIndex:0]];
  }
}

- (void)windowDidResize:(NSNotification *)aNotification {
  NSSize windowSize = [docWindow frame].size;
  [PREFERENCES setFloat:windowSize.width forKey:@"DocWindowWidth"];
  [PREFERENCES setFloat:windowSize.height forKey:@"DocWindowHeight"];
}

- (void)UndoManagerDidUndoOrRedo:(NSNotification *)aNotification {
  lineCountNum = [textView getLineCountInRange:NSMakeRange(0, [textView selectedRange].location)];
  [lineNumberTextField setIntValue:lineCountNum];
}

-(BOOL)validateMenuItem:(NSMenuItem*)anItem {
  SEL action = [anItem action];
  if (action == @selector(toggleSoftWrap:)) {
    [self isWrapped] ? [anItem setState:NSOnState] : [anItem setState:NSOffState];
  }
  else if (action == @selector(checkPerlSyntax:)) {
    NSString *contents = [[textView textStorage] string];
    NSRange fLineRange = [contents lineRangeForRange:NSMakeRange(0,0)];
        // We no longer check for anything but the shebang since who knows how they set up perl...
    if ((NSMaxRange(fLineRange) > 4) &&
        [[contents substringWithRange:NSMakeRange(0,3)] isEqualToString:@"#!/"]) {
      return YES;
    }
    return NO;
  }
  if ([[[anItem menu] title] isEqualToString:@"Line Endings"]) {
    ([anItem tag] == lineBreakType) ? [anItem setState:NSOnState] : [anItem setState:NSOffState];
  }
  return YES;
}

-(IBAction)checkPerlSyntax:(id)sender {
  NSString *alertTitle = @"perl Syntax Check";
  // Make sure document is saved
  if (([self fileName] == nil) || [docWindow isDocumentEdited]) {
    NSBeginAlertSheet(alertTitle, @"Cancel", nil, nil, docWindow, nil, nil, nil, nil, @"You must save your document before running a perl syntax check.");
  }
  else {
    NSString *executablePath = @"/usr/bin/perl";
    NSTask *perl = [[NSTask alloc] init];
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *handle = [pipe fileHandleForReading];
    NSString *output;
    [perl setLaunchPath:executablePath];
    [perl setArguments:[NSArray arrayWithObjects:@"-cw",[self fileName],nil]];
    [perl setStandardOutput:pipe];
    [perl setStandardError:pipe];
    [perl setCurrentDirectoryPath:[[self fileName] stringByDeletingLastPathComponent]];
    [perl launch];
    output = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    if ([output isEqualToString:[NSString stringWithFormat:@"%@ syntax OK\n", [self fileName]]]) {
      NSBeginAlertSheet(alertTitle, @"OK", nil, nil, docWindow, nil, nil, nil, nil, @"Your syntax is OK!");
    }
    else {
      NSString *sep = @"-----------------------------------";
      NSMutableString *temp = [[NSMutableString alloc] initWithFormat:@"Perl Syntax Check Failed\n%@\n%@",sep,output];
      [[MyDocumentController sharedInstance] newDocWithString:temp markChanged:NO wrap:NO];
    }
    [perl release];
    [output release];
  }
}

// Relative algorithm instead of recounting from zero. Fast but fucked if it ever gets off.
- (void)textViewDidChangeSelection:(NSNotification*)aNotification {
  // This stuff changes line count
  NSRange lastRange = [[[aNotification userInfo] objectForKey:@"NSOldSelectedCharacterRange"] rangeValue];
  NSRange currentRange = [textView selectedRange];
  if (currentRange.location > lastRange.location) {
    lineCountNum += [textView getLineCountInRange:NSMakeRange(lastRange.location, (currentRange.location - lastRange.location))] - 1;
    [lineNumberTextField setIntValue:lineCountNum];
  }
  else {
    // If range is less, characters could have been deleted so be careful
    lineCountNum = [textView getLineCountInRange:NSMakeRange(0, currentRange.location)];
    [lineNumberTextField setIntValue:lineCountNum];
  }
  // This stuff changes line position - this can be optimized!
  [positionTextField setIntValue:(currentRange.location - [[textView string] lineRangeForRange:currentRange].location + 1)];
}

-(IBAction)previewInBrowser:(id)sender {
  if (([self fileName] == nil) || [docWindow isDocumentEdited]) {
    NSBeginAlertSheet(@"Please Save Your Document", @"Cancel", nil, nil, docWindow, nil, nil, nil, nil, @"You must save your document before previewing it in a browser.");
  }
  else {
    NSString *browserToLaunch = [[PREFERENCES arrayForKey:@"WebBrowsers"] objectAtIndex:[sender tag]];
    if ([FILEMANAGER fileExistsAtPath:browserToLaunch]) {
      [[NSWorkspace sharedWorkspace] openFile:[self fileName] withApplication:browserToLaunch];
    }
    else {
      [BrowserPanel removeBrowserFromBrowserList:browserToLaunch];
      NSBeginAlertSheet(@"Browser Does Not Exist", @"Cancel", nil, nil, docWindow, nil, nil, nil, nil, @"The browser you are tying to use does not exist or cannot be accessed. It has been removed from your browser list. You may add it again by editing your browser list.");
    }
  }
}

-(void)changeDocEncoding:(NSStringEncoding)encoding {
  fileEncoding = encoding;
  [self encodingChanged:self];
}

-(NSStringEncoding)getEncoding {
  return fileEncoding;
}

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString*)replacementString {
  if (replacementString && ([replacementString length] == 1)) { // if single key pressed
    // Reject tabs if prefs say so, and then put in the correct number of spaces
    if ([PREFERENCES boolForKey:@"SpaceTabs"] && ([replacementString characterAtIndex:0] == NSTabCharacter)) {
      int spaces;
      NSMutableString *temp = [[NSMutableString alloc] init];
      for (spaces = [PREFERENCES integerForKey:@"SpaceTabNumber"]; spaces > 0; spaces--) {
        [temp appendString:@" "];
      }
      [textView replaceInRange:[textView selectedRange] with:temp];
      return NO;
    }
    else if ([PREFERENCES boolForKey:@"AutoIndent"] && ([replacementString characterAtIndex:0] == NSNewlineCharacter)) {
      NSString *string = [textView string];
      NSRange lastLine = [string lineRangeForRange:[textView selectedRange]];
      NSMutableString *temp = [[NSMutableString alloc] init];
      NSCharacterSet *whiteSet = [NSCharacterSet whitespaceCharacterSet];
      int i;
      [temp appendString:@"\n"];
      for (i = 0; i < lastLine.length; i++) {
        if ([whiteSet characterIsMember:[string characterAtIndex:(lastLine.location + i)]]) {
          [temp appendString:[string substringWithRange:NSMakeRange((lastLine.location + i), 1)]];
        }
        else {
          break;
        }
      }
      // test greater than one because it includes a newline already
      if ([temp length] > 1) {
        [textView replaceInRange:[textView selectedRange] with:temp];
        [temp release];
        return NO;
      }
      [temp release];
    }
  }
  return YES;
}

@end
