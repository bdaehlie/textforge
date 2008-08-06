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

#import "BrowserPanel.h"
#import "Common.h"
#import "MyDocumentController.h"

@implementation BrowserPanel

static BrowserPanel *sharedInstance = nil;

+ (BrowserPanel*)sharedInstance {
  return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init {
  if (sharedInstance) {
    [self dealloc];
  }
  else {
    sharedInstance = [super init];
  }
  return sharedInstance;
}

- (void)awakeFromNib {
  NSString *defaultBrowser = [PREFERENCES stringForKey:@"DefaultBrowser"];
  if ((defaultBrowser == nil) || [defaultBrowser isEqualToString:@""]) {
    [defaultBrowserTextField setStringValue:@"None"];
  }
  else {
    [defaultBrowserTextField setStringValue:[[NSFileManager defaultManager] displayNameAtPath:defaultBrowser]];
  }
  [browserTable reloadData];
}

/*
 ACTIONS
*/

- (IBAction)showPanel:(id)sender {
  if (!browserTable) {
    NSWindow *thePanel;
    [NSBundle loadNibNamed:@"Browsers" owner:self];
    thePanel = [browserTable window];
    [thePanel setMenu:nil];
    [thePanel center];
  }
  [[setDefaultButton window] makeKeyAndOrderFront:nil];
}

- (IBAction)addBrowser:(id)sender {
  NSOpenPanel *op = [NSOpenPanel openPanel];
  [op setCanChooseFiles:YES];
  [op setCanChooseDirectories:NO];
  [op setResolvesAliases:YES];
  [op setAllowsMultipleSelection:NO];
  [op beginSheetForDirectory:@"/Applications" file:nil types:[NSArray arrayWithObject:@"app"] modalForWindow:[setDefaultButton window] modalDelegate:self didEndSelector:@selector(addPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)addPanelDidEnd:(NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo {
  NSString *filePath = [[sheet filenames] objectAtIndex:0];
  [NSApp endSheet:sheet];
  [sheet orderOut:self];
  if (returnCode == NSOKButton) {
    if ([BrowserPanel addBrowserToBrowserList:filePath]) {
      // Added browser may have become the default
      [self updateDefaultBrowserTextField];
      [browserTable reloadData];
    }
    else {
      NSBeep();
      NSBeginAlertSheet(@"Browser Already Listed", @"Cancel", nil, nil, [browserTable window], nil, nil, nil, nil, @"The browser you chose is already listed.");
    }
  }
  [self showPanel:self];
}

- (IBAction)removeBrowser:(id)sender {
  NSString *defaultBrowser;
  [BrowserPanel removeBrowserFromBrowserList:[[PREFERENCES arrayForKey:@"WebBrowsers"] objectAtIndex:[browserTable selectedRow]]];
  // Reset the default browser field because it may have changed
  defaultBrowser = [PREFERENCES stringForKey:@"DefaultBrowser"];
  [self updateDefaultBrowserTextField];
  [browserTable reloadData];
}

- (IBAction)setDefaultBrowser:(id)sender {
  NSString *path = [[PREFERENCES arrayForKey:@"WebBrowsers"] objectAtIndex:[browserTable selectedRow]];
  [PREFERENCES setObject:path forKey:@"DefaultBrowser"];
  [defaultBrowserTextField setStringValue:[[NSFileManager defaultManager] displayNameAtPath:path]];
  [[MyDocumentController sharedInstance] updatePreviewInBrowserMenu];
}

/*
 METHODS
*/

+(NSString*)getDefaultSystemBrowser {
  NSURL *appURL = nil;
  OSStatus err;
  err = LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:@"http:"], kLSRolesAll, NULL, (CFURLRef *)&appURL);
  if (err == noErr) {
    return [appURL path];
  }
  else {
    return nil;
  }    
}

+(BOOL)addBrowserToBrowserList:(NSString*)browserToAdd {
  NSMutableArray *newBrowserList = [[NSMutableArray alloc] init];    
  [newBrowserList addObjectsFromArray:[PREFERENCES arrayForKey:@"WebBrowsers"]];
  // Make sure it doesn't already exist
  if (![newBrowserList containsObject:browserToAdd]) {
    [newBrowserList addObject:browserToAdd];
    [PREFERENCES setObject:newBrowserList forKey:@"WebBrowsers"];
    // If added browser is the only one in the list, make it default
    if ([newBrowserList count] == 1) {
      [BrowserPanel changeDefaultBrowserTo:browserToAdd];
    }
    [[MyDocumentController sharedInstance] updatePreviewInBrowserMenu];
    return YES;
  }
  else {
    [newBrowserList release];
    return NO;
  }
}

+(void)removeBrowserFromBrowserList:(NSString*)browserToRemove {
  NSMutableArray *newBrowserList = [[NSMutableArray alloc] init];
  [newBrowserList addObjectsFromArray:[PREFERENCES arrayForKey:@"WebBrowsers"]];
  [newBrowserList removeObject:browserToRemove];
  [PREFERENCES setObject:newBrowserList forKey:@"WebBrowsers"];
  if ([browserToRemove isEqualToString:[PREFERENCES stringForKey:@"DefaultBrowser"]]) {
    if ([newBrowserList count] > 0) {
      [PREFERENCES setObject:[newBrowserList objectAtIndex:0] forKey:@"DefaultBrowser"];
    }
    else {
      [PREFERENCES setObject:@"" forKey:@"DefaultBrowser"];
    }  
  }
  [[MyDocumentController sharedInstance] updatePreviewInBrowserMenu];
}

+(void)changeDefaultBrowserTo:(NSString*)newDefaultBrowser {
  // Make sure if its default, its in the browserlist
  if (newDefaultBrowser == nil) {
    newDefaultBrowser = @"";
  }
  if (![newDefaultBrowser isEqualToString:@""]) {
    [BrowserPanel addBrowserToBrowserList:newDefaultBrowser];
  }
  // Make it the default
  [PREFERENCES setObject:newDefaultBrowser forKey:@"DefaultBrowser"];
  [[MyDocumentController sharedInstance] updatePreviewInBrowserMenu];
}

-(void)updateDefaultBrowserTextField {
  NSString *defaultBrowser = [PREFERENCES stringForKey:@"DefaultBrowser"];
  if ((defaultBrowser == nil) || [defaultBrowser isEqualToString:@""]) {
    [defaultBrowserTextField setStringValue:@"None"];
  }
  else {
    [defaultBrowserTextField setStringValue:[[NSFileManager defaultManager] displayNameAtPath:defaultBrowser]];
  }
}

/*
 DELEGATES
*/

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
  int numberOfRows = [[PREFERENCES arrayForKey:@"WebBrowsers"] count];
  if (numberOfRows == 0) {
    [setDefaultButton setEnabled:NSOffState];
    [removeBrowserButton setEnabled:NSOffState];
  }
  else {
    [setDefaultButton setEnabled:NSOnState];
    [removeBrowserButton setEnabled:NSOnState];
  }
  return numberOfRows;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  return [[NSFileManager defaultManager] displayNameAtPath:[[PREFERENCES arrayForKey:@"WebBrowsers"] objectAtIndex:rowIndex]];
}

// Don't allow table editing
- (BOOL)tableView:(NSTableView*)aTableView shouldEditTableColumn:(NSTableColumn*)aTableColumn row:(int)rowIndex {
  return NO;
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView {
  return YES;
}

@end
