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

#import "QuickOpenPanel.h"
#import "Common.h"
#import "MyDocumentController.h"

@implementation QuickOpenPanel

static QuickOpenPanel *sharedInstance = nil;

+ (QuickOpenPanel*)sharedInstance {
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

/*
 ACTIONS
*/

- (IBAction)showPanel:(id)sender {
  if (!pathTextField) {
    NSWindow *thePanel;
    [NSBundle loadNibNamed:@"QuickOpen" owner:self];
    thePanel = [pathTextField window];
    [thePanel setMenu:nil];
    [thePanel center];
  }
  [[pathTextField window] makeKeyAndOrderFront:nil];
}

- (IBAction)ok:(id)sender {
  BOOL isDir, exists;
  NSString *pathToOpen = [pathTextField stringValue];
  [[sender window] close];
  pathToOpen = [pathToOpen stringByStandardizingPath];
  exists = [FILEMANAGER fileExistsAtPath:pathToOpen isDirectory:&isDir];
  if (exists && (!isDir)) {
    [[MyDocumentController sharedInstance] checkFileWritePermissions:[NSArray arrayWithObject:pathToOpen]];
    [[MyDocumentController sharedInstance] openDocumentWithContentsOfFile:pathToOpen display:YES];
  }
  else {
    NSBeep();
    NSRunCriticalAlertPanel(@"File Doesn't Exist", @"There is no file at the path you entered.", @"OK", nil, nil);
  }
}

- (IBAction)cancel:(id)sender {
  // clear it so its not remembered because user canceled
  [pathTextField setStringValue:@""];
  [[sender window] close];
}

@end
