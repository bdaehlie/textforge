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

#import "tfTextView.h"
#import "Common.h"
#import "jaStringMethods.h"
#import "MyDocument.h"
#import "MyDocumentController.h"

const float jReallyBigNumber = 2.0e12;

@implementation tfTextView

// In TextForge, always init with this method
- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)aTextContainer {
  if (self = [super initWithFrame:frameRect textContainer:aTextContainer]) {
    // Sets up initial config values
    [self wrap];
    [self setTextContainerInset:NSMakeSize(1.0,3.0)];
    [self setImportsGraphics:NO];
    [self setFont:CURRENTFONT];
    // it isn't really a rich text document, but we use rich text display (i.e. color scheming)
    [self setRichText:YES];
    [self setSmartInsertDeleteEnabled:[PREFERENCES boolForKey:@"UseSmartInsertDelete"]];
    [self setBackgroundColor:[NSUnarchiver unarchiveObjectWithData:[PREFERENCES objectForKey:@"BGColor"]]];
    [self setDrawsBackground:YES];
    textStorage = [self textStorage];
    [textStorage setDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorsDidChange:) name:@"ColorsDidChangeNotification" object:nil];
  }
  return self;
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

-(unsigned)contentLength {
  return [[self textStorage] length];
}

/*
 Return values:
 [-1] if problem occures
 [>=0] number of replacements made
 
 Supports undo
*/
-(unsigned)replaceAll:(NSString*)targetString with:(NSString*)replaceString inSelectionOnly:(BOOL)entireFile ignoreCase:(BOOL)ignoreCase {
  if (![self isEditable]) {
    return -1;
  }
  else {
    NSString *textContents = [self string];
    NSRange replaceRange = !entireFile ? NSMakeRange(0, [textStorage length]) : [self selectedRange];
    unsigned searchOption = (ignoreCase ? NSCaseInsensitiveSearch : 0);
    unsigned replaced = 0;
    NSRange firstOccurence;
    // Find the first occurence of the string being replaced; if not found, we're done!
    firstOccurence = [textContents rangeOfString:targetString options:searchOption range:replaceRange];
    if (firstOccurence.length > 0) {
      NSAutoreleasePool *pool;
      NSMutableAttributedString *temp;	/* This is the temporary work string in which we will do the replacements... */
      NSRange rangeInOriginalString;	/* Range in the original string where we do the searches */
      // Find the last occurence of the string and union it with the first occurence to compute the tightest range...
      rangeInOriginalString = replaceRange = NSUnionRange(firstOccurence, [textContents rangeOfString:targetString options:NSBackwardsSearch|searchOption range:replaceRange]);
      temp = [[NSMutableAttributedString alloc] init];
      [temp beginEditing];
      // The following loop can execute an unlimited number of times, and it could have autorelease activity.
      // To keep things under control, we use a pool, but to be a bit efficient, instead of emptying everytime through
      // the loop, we do it every so often. We can only do this as long as autoreleased items are not supposed to
      // survive between the invocations of the pool!
      pool = [[NSAutoreleasePool alloc] init];
      while (rangeInOriginalString.length > 0) {
        NSRange foundRange = [textContents rangeOfString:targetString options:searchOption range:rangeInOriginalString];
        if (foundRange.length == 0) {
          [temp appendAttributedString:[textStorage attributedSubstringFromRange:rangeInOriginalString]];	// Copy the remainder
          rangeInOriginalString.length = 0;	// And signal that we're done
        } else {
                    // Copy upto the start of the found range plus one char (to maintain attributes with the overlap)...
          NSRange rangeToCopy = NSMakeRange(rangeInOriginalString.location, foundRange.location - rangeInOriginalString.location + 1);
          [temp appendAttributedString:[textStorage attributedSubstringFromRange:rangeToCopy]];
          [temp replaceCharactersInRange:NSMakeRange([temp length] - 1, 1) withString:replaceString];
          rangeInOriginalString.length -= NSMaxRange(foundRange) - rangeInOriginalString.location;
          rangeInOriginalString.location = NSMaxRange(foundRange);
          replaced++;
          if (replaced % 100 == 0) {	// Refresh the pool... See warning above!
            [pool release];
            pool = [[NSAutoreleasePool alloc] init];
          }
        }
      }
      [pool release];
      [temp endEditing];
      // Now modify the original string
      if (![self replaceInRange:replaceRange with:[temp string]]) {
        replaced = 0;
      }
      [temp release];
    }
    return replaced;
  }
}

-(BOOL)replaceInRange:(NSRange)replaceRange with:(NSString*)replacementString {
  if ([self shouldChangeTextInRange:replaceRange replacementString:replacementString] &&
      (NSMaxRange(replaceRange) <= [[self textStorage] length])) {
    [[self textStorage] replaceCharactersInRange:replaceRange withString:replacementString];
    [self didChangeText];
    return TRUE;
  }
  return FALSE;
}

- (void)setCursorToLine:(unsigned)line {
  unsigned count = line;
  NSString *string = [self string];
  NSRange nextRange = NSMakeRange(0,0);
  NSRange foundRange = NSMakeRange(0,0);
  while (count > 1) {
    if (NSMaxRange(nextRange) < [string length]) {
      foundRange = [string lineRangeForRange:nextRange];
      nextRange = NSMakeRange(NSMaxRange(foundRange),0);
    }
    else {
      NSBeep();
      break;
    }
    count--;
  }
  [self setSelectedRange:[string lineRangeForRange:NSMakeRange(NSMaxRange(foundRange),0)]];
}

-(unsigned)getLineCountInRange:(NSRange)range {
  unsigned count = 1;
  NSString *string = [[self string] substringWithRange:range];
  NSRange temp;
  NSRange searchRange = NSMakeRange(0, [string lineRangeForRange:NSMakeRange([string length],0)].location);
  while (searchRange.length > 0) {
    temp = [string lineRangeForRange:NSMakeRange(NSMaxRange(searchRange),0)];
    if (temp.location == 0) {
      break;
    }
    searchRange = NSMakeRange(0,(temp.location - 1));
    count++;
  }
  return count;
}

- (unsigned)getCharacterCountInRange:(NSRange)range {
  NSCharacterSet *countSet = [NSCharacterSet alphanumericCharacterSet];
  NSString *string = [[[self string] substringWithRange:range] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  int length = [string length];
  int count = 0;
  int i;
  for (i = 0; i < length; i++) {
    if ([countSet characterIsMember:[string characterAtIndex:i]]) {
      count++;
    }
  }
  return count;
}

-(unsigned)getWordCountInRange:(NSRange)range {
  NSString *string = [[[self string] substringWithRange:range] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  NSCharacterSet *countSet = [NSCharacterSet alphanumericCharacterSet];
  int length = [string length];
  int count = 0;
  int i;
  BOOL inWord = FALSE;
  for (i = 0; i < length; i++) {
    if ([countSet characterIsMember:[string characterAtIndex:i]]) {
      if (!inWord) {
        inWord = TRUE;
        count++;
      }
    }
    else {
      if (inWord) {
        inWord = FALSE;
      }
    }
  }
  return count;
}

-(void)wrap {
  NSTextContainer *textContainer = [self textContainer];
  NSScrollView *scrollView = [self enclosingScrollView];
  // Set up NSScrollView
  [scrollView setHasHorizontalScroller:NO];
  [scrollView setHasVerticalScroller:YES];
  [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [[scrollView contentView] setAutoresizesSubviews:YES];
  // Create and configure NSTextContainer
  [textContainer setContainerSize:NSMakeSize([scrollView contentSize].width, jReallyBigNumber)];
  [textContainer setWidthTracksTextView:YES];
  [textContainer setHeightTracksTextView:NO];
  // Create and configure NSTextView
  [self setMinSize:[scrollView contentSize]];
  [self setMaxSize:NSMakeSize(jReallyBigNumber, jReallyBigNumber)];
  [self setHorizontallyResizable:YES];
  [self setVerticallyResizable:YES];
  [self setAutoresizingMask:NSViewWidthSizable];
  [self setAllowsUndo:YES];
}

-(void)noWrap {
  NSTextContainer *textContainer = [self textContainer];
  NSScrollView *scrollView = [self enclosingScrollView];
  // Set up NSScrollView
  [scrollView setHasHorizontalScroller:YES];
  [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [[scrollView contentView] setAutoresizesSubviews:YES];
  // Configure NSTextContainer
  [textContainer setContainerSize:NSMakeSize(jReallyBigNumber, jReallyBigNumber)];
  [textContainer setWidthTracksTextView:NO];
  [textContainer setHeightTracksTextView:NO];
  // Configure NSTextView
  [self setMinSize:[scrollView contentSize]];
  [self setMaxSize:NSMakeSize(jReallyBigNumber, jReallyBigNumber)];
  [self setHorizontallyResizable:YES];
  [self setVerticallyResizable:YES];
  [self setAutoresizingMask:NSViewNotSizable];
  [self setAllowsUndo:YES];
}

- (void)paste:(id)sender {
  NSString *pasteBoardString = [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];
  if (pasteBoardString != nil) {
    NSMutableString *mutString = [[NSMutableString alloc] initWithString:pasteBoardString];
    [self insertText:mutString];
    [mutString release];
  }
}

-(void)setParentDocument:(MyDocument*)document {
  parentDocument = document;
}

-(MyDocument*)getParentDocument {
  return parentDocument;
}

-(void)setPlainColor:(NSColor*)color {
  if (plainColor != nil) {
    [plainColor release];
  }
  plainColor = [color retain];
  [self setTextColor:plainColor];
}

-(void)setBackgroundColor:(NSColor*)aColor {
  [super setBackgroundColor:[aColor colorWithAlphaComponent:[PREFERENCES floatForKey:@"AlphaValue"]]];
}

-(void)colorsDidChange:(NSNotification *)aNotification {
  float darkness;
  NSColor *backgroundColor = [[[NSUnarchiver unarchiveObjectWithData:[PREFERENCES objectForKey:@"BGColor"]] colorWithAlphaComponent:[PREFERENCES floatForKey:@"AlphaValue"]] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
  [self setBackgroundColor:backgroundColor];
  [self setPlainColor:[NSUnarchiver unarchiveObjectWithData:[PREFERENCES objectForKey:@"FGColor"]]];
  // this isn't arbitrary - its the equation for calculating darkness on a scale of 0-1, where lighter colors have higher values
  darkness = ((222 * [backgroundColor redComponent]) + (707 * [backgroundColor greenComponent]) + (71 * [backgroundColor blueComponent])) / 1000;
  if (darkness > 0.5) {
    [self setInsertionPointColor:[NSColor blackColor]];
    [[[self enclosingScrollView] contentView] setDocumentCursor:[NSCursor IBeamCursor]];
  }
  else {
    [self setInsertionPointColor:[NSColor whiteColor]];
    [[[self enclosingScrollView] contentView] setDocumentCursor:[[MyDocumentController sharedDocumentController] getLightCursor]];
  }
}

@end
