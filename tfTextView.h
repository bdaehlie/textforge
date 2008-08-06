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

#import <AppKit/AppKit.h>

@class MyDocument;
@interface tfTextView : NSTextView {
  @private
  MyDocument* parentDocument;
  NSColor *plainColor;
  NSTextStorage *textStorage;
}

// Returns the string length of the content
-(unsigned)contentLength;
-(unsigned)replaceAll:(NSString*)targetString with:(NSString*)replaceString inSelectionOnly:(BOOL)entireFile ignoreCase:(BOOL)ignoreCase;
-(BOOL)replaceInRange:(NSRange)replaceRange with:(NSString*)replacementString;
-(void)setCursorToLine:(unsigned)line;
-(unsigned)getLineCountInRange:(NSRange)range;
-(unsigned)getCharacterCountInRange:(NSRange)range;
-(unsigned)getWordCountInRange:(NSRange)range;
-(void)wrap;
-(void)noWrap;
-(void)paste:(id)sender;
-(void)setParentDocument:(MyDocument*)document;
-(MyDocument*)getParentDocument;
-(void)setPlainColor:(NSColor*)color;
-(void)colorsDidChange:(NSNotification *)aNotification;
-(void)setBackgroundColor:(NSColor*)aColor;

@end
