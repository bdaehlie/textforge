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
#import "Common.h"

@interface MyDocumentController : NSDocumentController
{
  IBOutlet NSMenuItem *previewInBrowserMenu;
  IBOutlet NSMenuItem *encodingMenuItem;
  IBOutlet NSMenuItem *syntaxColoringMenu;
}

+(MyDocumentController*)sharedInstance;
-(IBAction)showPreferences:(id)sender;
-(BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;
-(IBAction)newDocWithSelection:(id)sender;
-(void)newDocWithString:(NSString*)string markChanged:(BOOL)changed wrap:(BOOL)wrap;
-(NSCursor*)getLightCursor;
-(IBAction)editBrowserList:(id)sender;
-(void)updatePreviewInBrowserMenu;
-(IBAction)previewInBrowser:(id)sender;
-(BOOL)validateMenuItem:(NSMenuItem*)anItem;
-(IBAction)newXHTMLDoc:(id)sender;
-(IBAction)changeDocEncoding:(id)sender;
-(IBAction)openDocument:(id)sender;
-(BOOL)checkFileWritePermissions:(NSArray*)files;
+(void)addColorDefaultsToDict:(NSMutableDictionary*)dict;
-(NSTextView *)textObjectToSearchIn;
-(void)jumpToSelection:(id)sender;

@end
