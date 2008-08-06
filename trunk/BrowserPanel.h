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

@interface BrowserPanel : NSObject {
  IBOutlet NSTableView *browserTable;
  IBOutlet NSButton *addBrowserButton;
  IBOutlet NSButton *removeBrowserButton;
  IBOutlet NSButton *setDefaultButton;
  IBOutlet NSTextField *defaultBrowserTextField;
}

+ (BrowserPanel*)sharedInstance;
- (id)init;
- (void)awakeFromNib;
- (IBAction)showPanel:(id)sender;
- (IBAction)addBrowser:(id)sender;
- (void)addPanelDidEnd:(NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo;
- (IBAction)removeBrowser:(id)sender;
- (IBAction)setDefaultBrowser:(id)sender;
+(NSString*)getDefaultSystemBrowser;
+(BOOL)addBrowserToBrowserList:(NSString*)browserToAdd;
+(void)removeBrowserFromBrowserList:(NSString*)browserToRemove;
+(void)changeDefaultBrowserTo:(NSString*)newDefaultBrowser;
-(void)updateDefaultBrowserTextField;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (BOOL)tableView:(NSTableView*)aTableView shouldEditTableColumn:(NSTableColumn*)aTableColumn row:(int)rowIndex;
- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView;

@end
