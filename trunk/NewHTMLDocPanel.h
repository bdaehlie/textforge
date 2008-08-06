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

@interface NewHTMLDocPanel : NSObject {
  IBOutlet NSButton *insertXMLDeclarationButton;
  IBOutlet NSButton *insertDOCTYPEButton;
  IBOutlet NSTextField *titleTextField;
  IBOutlet NSPopUpButton *langPopUp;
  IBOutlet NSPopUpButton *charsetPopUp;
  IBOutlet NSPopUpButton *DOCTYPEPopUp;
  IBOutlet NSButton *cancelButton;
  IBOutlet NSButton *createButton;
}

+ (NewHTMLDocPanel*)sharedInstance;
- (id)init;
- (void)awakeFromNib;
- (IBAction)showPanel:(id)sender;
- (IBAction)hidePanel:(id)sender;
- (IBAction)createDoc:(id)sender;

@end
