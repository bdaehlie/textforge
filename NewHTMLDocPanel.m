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

#import "NewHTMLDocPanel.h"
#import "Common.h"
#import "MyDocumentController.h"
#import "jaStringMethods.h"

@implementation NewHTMLDocPanel

static NewHTMLDocPanel *sharedInstance = nil;

+ (NewHTMLDocPanel*)sharedInstance {
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

// This method uses dangerous techniques for selecting default items
- (void)awakeFromNib {
  NSDictionary *langDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"lang_abbr" ofType:@"plist" inDirectory:@"html_docs"]];
  NSDictionary *csDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"html_encodings" ofType:@"plist" inDirectory:@"html_docs"]];
  // Set up languages
  [langPopUp removeAllItems];
  [langPopUp addItemsWithTitles:[langDict allKeys]];
  [langPopUp selectItemWithTitle:@"English"];
  // Set up charsets
  [charsetPopUp removeAllItems];
  [charsetPopUp addItemsWithTitles:[csDict allKeys]];
  [charsetPopUp selectItemAtIndex:2];
}

/*
 ACTIONS
*/

- (IBAction)showPanel:(id)sender {
  if (!createButton) {
    NSWindow *thePanel;
    [NSBundle loadNibNamed:@"HTMLDocSetup" owner:self];
    thePanel = [createButton window];
    [thePanel setMenu:nil];
    [thePanel center];
  }
  // Setup/reset of title field
  [titleTextField setStringValue:@"Untitled"];
  [[createButton window] makeKeyAndOrderFront:nil];
}

- (IBAction)hidePanel:(id)sender {
  [[createButton window] close];
}

- (IBAction)createDoc:(id)sender {
  NSMutableString *newFileText = [[NSMutableString alloc] init];
  NSDictionary *langDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"lang_abbr" ofType:@"plist" inDirectory:@"html_docs"]];
  NSDictionary *charsetDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"html_encodings" ofType:@"plist" inDirectory:@"html_docs"]];
  [self hidePanel:self];
    // 
  if ([insertXMLDeclarationButton state] == NSOnState) {
    [newFileText appendString:[NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"%@\"?>\n", [charsetDict objectForKey:[charsetPopUp titleOfSelectedItem]]]];
  }
  if ([insertDOCTYPEButton state] == NSOnState) {
    NSDictionary *doctypeDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"doctypes" ofType:@"plist" inDirectory:@"html_docs"]];
    [newFileText appendString:[NSString stringWithFormat:@"%@\n", [doctypeDict objectForKey:[jaStringMethods intAsString:[[DOCTYPEPopUp selectedItem] tag]]]]];
  }
  [newFileText appendString:[NSString stringWithFormat:@"<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"%@\">\n", [langDict objectForKey:[langPopUp titleOfSelectedItem]]]];
  [newFileText appendString:[NSString stringWithFormat:@"<head>\n\t<meta http-equiv=\"content-type\" content=\"text/html; charset=%@\" />\n", [charsetDict objectForKey:[charsetPopUp titleOfSelectedItem]]]];
  [newFileText appendString:[NSString stringWithFormat:@"\t<title>%@</title>\n</head>\n<body>\n\n</body>\n</html>\n", [titleTextField stringValue]]];
  [[MyDocumentController sharedInstance] newDocWithString:newFileText markChanged:YES wrap:YES];
}

@end
