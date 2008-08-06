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

@interface PrefController : NSObject {
  IBOutlet NSWindow *window;
  IBOutlet NSView *loadingView;
  NSMutableArray *panes;
  NSMutableDictionary *loadedPanes;
  NSString *currentPaneIdentifier;
}

+(PrefController *)sharedInstance;
-(IBAction)showWindow:(id)sender;
-(IBAction)selectPane:(id)sender;
-(void)displayPane:(NSString *)identifier;
-(NSString *)labelForPaneBundle:(NSBundle *)bundle;
-(NSImage *)imageForPaneBundle:(NSBundle *)bundle;
-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;    
-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
- (void)changeFont:(id)fontManager;

@end
