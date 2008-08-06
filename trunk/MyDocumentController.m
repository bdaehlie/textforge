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

#import "MyDocumentController.h"
#import "MyDocument.h"
#import "PrefController.h"
#import "BrowserPanel.h"
#import "NewHTMLDocPanel.h"
#import "QuickOpenPanel.h"
#import "tfTextView.h"
#import "Common.h"
#import "EncodingManager.h"

@implementation MyDocumentController

+ (void)initialize {
  // Initialize defaults
  NSMutableDictionary *defaultPrefs = [NSMutableDictionary dictionary];
  [super initialize];
  [defaultPrefs setObject:@"1.0" forKey:@"AlphaValue"];
  // 1 is the number for UNIX line break, 2 for Mac, 3 for DOS
  [defaultPrefs setObject:[NSNumber numberWithInt:1] forKey:@"LineBreakFormat"];
  [defaultPrefs setObject:@"YES" forKey:@"NewDocOnLaunch"];
  [defaultPrefs setObject:@"NO" forKey:@"UseSmartInsertDelete"];
  [defaultPrefs setObject:[NSNumber numberWithInt:NoStringEncoding] forKey:@"SaveEncoding"];
  [defaultPrefs setObject:[NSNumber numberWithInt:NoStringEncoding] forKey:@"OpenEncoding"];
  [defaultPrefs setObject:@"8" forKey:@"SpaceTabNumber"];
  [defaultPrefs setObject:@"NO" forKey:@"AutoIndent"];
  [defaultPrefs setObject:@"NO" forKey:@"SpaceTabs"];
  [defaultPrefs setObject:@"510.0" forKey:@"DocWindowWidth"];
  [defaultPrefs setObject:@"500.0" forKey:@"DocWindowHeight"];
  [defaultPrefs setObject:[[[NSMutableArray alloc] init] autorelease] forKey:@"WebBrowsers"];
  [defaultPrefs setObject:@"" forKey:@"DefaultBrowser"];
  [defaultPrefs setObject:@"" forKey:@"LastOpenLocation"];
  [defaultPrefs setObject:@"YES" forKey:@"SoftWrapDefault"];
  [self addColorDefaultsToDict:defaultPrefs];
  [PREFERENCES registerDefaults:defaultPrefs];
}

static MyDocumentController *sharedInstance = nil;

+(MyDocumentController*)sharedInstance {
  return sharedInstance ? sharedInstance : [[self alloc] init];
}

-(id)init {
  if (sharedInstance) {
    [self dealloc];
  }
  else {
    sharedInstance = [super init];
  }
  return sharedInstance;
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification {
  int i;
  NSMenuItem *tempItem;
  NSMenu *eMenu = [encodingMenuItem submenu];
  NSArray *availableEncodings = [EncodingManager allAvailableStringEncodings];
  NSString *defaultBrowserPath = [PREFERENCES stringForKey:@"DefaultBrowser"];
  NSArray *browserList = [PREFERENCES objectForKey:@"WebBrowsers"];
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(useSmartInsertDeleteChanged:) name:@"UseSmartInsertDeleteChanged" object:nil];
  
  [center addObserver:self selector:@selector(opacityChanged:) name:@"OpacityChanged" object:nil];
  // Remove any incorrect browsers from BrowserList
  for (i = 0; i < [browserList count]; i++) {
    if (![FILEMANAGER isExecutableFileAtPath:[browserList objectAtIndex:i]]) {
      [BrowserPanel removeBrowserFromBrowserList:[browserList objectAtIndex:i]];
    }
  }
  // Find default browser if one isn't already found, update preview-in-browser menu
  if ((defaultBrowserPath == nil) || [defaultBrowserPath isEqualToString:@""] || ([browserList count] == 0)) {
    NSString *sysBrowser = [BrowserPanel getDefaultSystemBrowser];
    if (sysBrowser != nil) {
      [BrowserPanel changeDefaultBrowserTo:sysBrowser];
    }
  }
  [self updatePreviewInBrowserMenu];
  // Set up the encoding menu
  [eMenu removeItemAtIndex:0];
  for (i = 0; i < [availableEncodings count]; i++) {
    tempItem = [[NSMenuItem alloc] initWithTitle:[NSString localizedNameOfStringEncoding:[[availableEncodings objectAtIndex:i] intValue]] action:@selector(changeDocEncoding:) keyEquivalent:@""];
    [tempItem setTag:[[availableEncodings objectAtIndex:i] intValue]];
    [tempItem setTarget:self];
    [eMenu addItem:tempItem];
  }
  tempItem = [[NSMenuItem alloc] initWithTitle:@"Automatic" action:@selector(changeDocEncoding:) keyEquivalent:@""];
  [tempItem setTag:-1];
  [tempItem setTarget:self];
  [eMenu insertItem:tempItem atIndex:0];
}

-(IBAction)changeDocEncoding:(id)sender {
  [(MyDocument*)[self currentDocument] changeDocEncoding:(unsigned)[sender tag]];
}

-(BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
  return [PREFERENCES boolForKey:@"NewDocOnLaunch"];
}

- (IBAction)showPreferences:(id)sender {
  [[PrefController sharedInstance] showWindow:sender];
}

// Can be more efficient and global if based on actions...
-(BOOL)validateMenuItem:(NSMenuItem*)anItem {
  SEL action = [anItem action];
  if ([[[anItem menu] title] isEqualToString:@"Search"]) {
    return ([[[NSDocumentController sharedDocumentController] documents] count] > 0);
  }
  if (action == @selector(newDocWithSelection:)) {
    MyDocument *current = [self currentDocument];
    if (current == nil || ([[current getTextView] selectedRange].length == 0)) {
      return NO;
    }
  }
  else if (action == @selector(previewInBrowser:)) {
    if ([self currentDocument] == nil) {
      return NO;
    }
  }
  else if (action == @selector(changeDocEncoding:)) {
    if ([self currentDocument] == nil) {
      return NO;
    }
    else {
      if ([anItem tag] == [(MyDocument*)[self currentDocument] getEncoding]) {
        [anItem setState:NSOnState];
      }
      else {
        [anItem setState:NSOffState];
      }
    }
  }
  return YES;
}

-(IBAction)newDocWithClipboard:(id)sender {
  NSTextView *currentDocTextView;
  [self newDocument:self];
  currentDocTextView = [[self currentDocument] getTextView];
  [currentDocTextView didChangeText];
  [currentDocTextView paste:self];
}

-(IBAction)newDocWithSelection:(id)sender {
  NSTextView *textView = [[self currentDocument] getTextView];
  [self newDocWithString:[[textView string] substringWithRange:[textView selectedRange]] markChanged:YES wrap:YES];
}

-(void)newDocWithString:(NSString*)string markChanged:(BOOL)changed wrap:(BOOL)wrap {
  // The order of declarations and assignments is critical! Don't try to shorten this without paying close attention.
  NSTextView *currentTextView;
  NSAttributedString *attString;
  [self newDocument:self];
  currentTextView = [[self currentDocument] getTextView];
  attString = [[NSAttributedString alloc] initWithString:string attributes:[currentTextView typingAttributes]];
  [[currentTextView textStorage] appendAttributedString:attString];
  [attString release];
  if (changed) {
    [currentTextView didChangeText];
  }
  if (!wrap) {
    [[[self currentDocument] getTextView] noWrap];
  }
}

-(NSCursor*)getLightCursor {
  return [[[NSCursor alloc] initWithImage:[[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TIbeam" ofType:@"tiff" inDirectory:nil]] autorelease] hotSpot:NSMakePoint(4.0, 8.0)] autorelease];
}

-(IBAction)editBrowserList:(id)sender {
  [[BrowserPanel sharedInstance] showPanel:sender];
}

-(void)updatePreviewInBrowserMenu {
  NSMenu *bpMenu = [previewInBrowserMenu submenu];
  int currentBrowserMenuItemCount = [[bpMenu itemArray] count] - 2;
  NSMutableArray *browserPaths = [NSMutableArray arrayWithArray:[PREFERENCES arrayForKey:@"WebBrowsers"]];
  NSMenuItem *newMenuItem;
  NSImage *appIcon;
  NSString *defaultBrowser = [PREFERENCES objectForKey:@"DefaultBrowser"];
  int i;
  int defaultIndex = -1;
  // Move default browser to top of list if it exists
  for (i = 0; i < [browserPaths count]; i++) {
    if ([[browserPaths objectAtIndex:i] isEqualToString:defaultBrowser]) {
      defaultIndex = i;
    }
  }
  // remove old menu items
  for (i = (currentBrowserMenuItemCount - 1); i >= 0; i--) {
    [bpMenu removeItemAtIndex:i];
  }
  // add new menu items
  for (i = ([browserPaths count] - 1); i >= 0; i--) {
    newMenuItem = [[NSMenuItem alloc] initWithTitle:[[NSFileManager defaultManager] displayNameAtPath:[browserPaths objectAtIndex:i]] action:@selector(previewInBrowser:) keyEquivalent:@""];
    appIcon = [[NSWorkspace sharedWorkspace] iconForFile:[browserPaths objectAtIndex:i]];
    [appIcon setSize:NSMakeSize(16.0,16.0)];
    [newMenuItem setImage:appIcon];
    [newMenuItem setTag:i];
    [newMenuItem setTarget:self];
    [bpMenu insertItem:newMenuItem atIndex:0];
  }
  if (defaultIndex != -1) {
    NSMenuItem *defaultBrowserMenuItem = [[bpMenu itemAtIndex:defaultIndex] retain];
    [bpMenu removeItemAtIndex:defaultIndex];
    [bpMenu insertItem:defaultBrowserMenuItem atIndex:0];
    [defaultBrowserMenuItem release];
  }
  if ([[bpMenu itemArray] count] > 2) {
    [[bpMenu itemAtIndex:0] setKeyEquivalent:@"B"];
  }
}

-(IBAction)previewInBrowser:(id)sender {
  [[self currentDocument] previewInBrowser:sender];
}

-(IBAction)newXHTMLDoc:(id)sender {
  [[NewHTMLDocPanel sharedInstance] showPanel:self];
}

// Override in order to add accessory view
- (IBAction)openDocument:(id)sender {
  int i, tag, oldtag;
  BOOL isDir, dirExists;
  NSArray *filenames;
  NSString *openLocation = [PREFERENCES stringForKey:@"LastOpenLocation"];
  NSOpenPanel *op = [NSOpenPanel openPanel];
  dirExists = [FILEMANAGER fileExistsAtPath:openLocation isDirectory:&isDir];
  if (!isDir) {
    dirExists = NO;
  }
  if ((openLocation == @"") || !dirExists) {
    openLocation = NSHomeDirectory();
  }
  [op setCanChooseDirectories:NO];
  [op setCanChooseFiles:YES];
  [op setResolvesAliases:YES];
  [op setAllowsMultipleSelection:YES];
  [op setAccessoryView:[[EncodingManager sharedInstance] getOASAView:TRUE]];
  [op runModalForDirectory:openLocation file:nil types:nil];
  filenames = [op filenames];
  tag = [[((NSPopUpButton*)[[[[[op accessoryView] subviews] objectAtIndex:0] subviews] objectAtIndex:0]) selectedItem] tag];
  // Change prefs while the docs are opening so code elsewhere doesn't need to change (it depends on the prefs). Save the old ones.
  oldtag = [PREFERENCES integerForKey:@"OpenEncoding"];
  [PREFERENCES setInteger:tag forKey:@"OpenEncoding"];
  // Make sure to warn the user if he/she can't write to any files
  [self checkFileWritePermissions:filenames];
  for (i = 0; i < [filenames count]; i++) {
    [self openDocumentWithContentsOfFile:[filenames objectAtIndex:i] display:YES];
  }
  // Set the prefs back after opening
  [PREFERENCES setInteger:oldtag forKey:@"OpenEncoding"];
  // Save the last open location
  [PREFERENCES setObject:[[filenames objectAtIndex:0] stringByDeletingLastPathComponent] forKey:@"LastOpenLocation"];
}

-(IBAction)openQuickly:(id)sender {
  [[QuickOpenPanel sharedInstance] showPanel:self];
}

// returns yes if everything is OK (i.e. you can write to the file), or the file doesn't exist
// This should be called before opening one or a group of files
-(BOOL)checkFileWritePermissions:(NSArray*)files {
  int i, count;
  count = [files count];
  for (i = 0; i < count; i++) {
    if (![FILEMANAGER isWritableFileAtPath:[files objectAtIndex:i]]) {
      NSMutableString *errString;
      if (count == 1) {
        errString = [[NSMutableString alloc] initWithFormat:@"You do not have permission to write to the file \"%@\". You will not be able to edit it.", [files objectAtIndex:0]];
      }
      else {
        errString = [[NSMutableString alloc] initWithString:@"You do not have permission to write to one or more of the files you just opened. You will not be able to edit some of them."];
      }
      NSRunCriticalAlertPanel(@"Insufficient Privileges", errString, @"OK", nil, nil);
      [errString release];
      return NO;
    }
  }
  return YES;
}

+(void)addColorDefaultsToDict:(NSMutableDictionary*)dict {
  [dict setObject:[NSArchiver archivedDataWithRootObject:[NSColor blackColor]] forKey:@"FGColor"];
  [dict setObject:[NSArchiver archivedDataWithRootObject:[NSColor whiteColor]] forKey:@"BGColor"];
}

- (NSTextView *)textObjectToSearchIn {
  id obj = [[NSApp mainWindow] firstResponder];
  return (obj && [obj isKindOfClass:[NSTextView class]]) ? obj : nil;
}

- (void)jumpToSelection:(id)sender {
  NSTextView *textView = [self textObjectToSearchIn];
  if (textView) {
    [textView scrollRangeToVisible:[textView selectedRange]];
  }
}

-(void)useSmartInsertDeleteChanged:(NSNotification *)note {
  NSButton *button = [note object];
  BOOL use = [button state];
  NSArray *docs = [self documents];
  tfTextView *temp;
  int i;
  // change in all existing windows
  for (i = 0; i < [docs count]; i++) {
    temp = [[docs objectAtIndex:i] getTextView];
    [temp setSmartInsertDeleteEnabled:use];
  }
}

-(void)opacityChanged:(NSNotification *)note {
  NSArray *docs = [self documents];
  tfTextView *temp;
  // change alpha value for all existing windows now
  int i;
  for (i = 0; i < [docs count] ; i++) {
    temp = [[docs objectAtIndex:i] getTextView];
    [temp setBackgroundColor:[temp backgroundColor]];
    // Set the insertion point color to itself or it'll draw with a funny background
    [temp setInsertionPointColor:[temp insertionPointColor]];
    [temp display];
  }
}

@end
