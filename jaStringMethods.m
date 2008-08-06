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

#import "jaStringMethods.h"

@implementation jaStringMethods

// IS case sensitive
+(NSMutableString*)replaceString:(NSString*)stringToReplace inString:(NSMutableString*)string withString:(NSString*)replacementString {
  [string setString:[[string componentsSeparatedByString:stringToReplace]
                                 componentsJoinedByString:replacementString]];
  return string;
}

+(NSString*)intAsString:(int)i {
  return [[NSNumber numberWithInt:i] stringValue];
}

+(NSString*)floatAsString:(float)i {
  return [[NSNumber numberWithFloat:i] stringValue];
}

+(float)stringAsFloat:(NSString*)i {
  return [i floatValue];
}

+(int)stringAsInt:(NSString*)i {
  return [i intValue];
}

+(NSMutableString*)convertStringToUnix:(NSMutableString*)string {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [string setString:[[string componentsSeparatedByString:@"\r\n"]
                                  componentsJoinedByString:@"\n"]];
  [string setString:[[string componentsSeparatedByString:@"\r"]
                                 componentsJoinedByString:@"\n"]];
  [pool release];
  return string;
}

+(NSMutableString*)convertStringToMac:(NSMutableString*)string {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [string setString:[[string componentsSeparatedByString:@"\r\n"]
                                  componentsJoinedByString:@"\r"]];
  [string setString:[[string componentsSeparatedByString:@"\n"]
                                  componentsJoinedByString:@"\r"]];
  [pool release];
  return string;
}

// NOTE: The order of substitution is critical in converting to the DOS line break format.
+(NSMutableString*)convertStringToDOS:(NSMutableString*)string {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSMutableString *magicString = [[NSMutableString alloc] initWithString:@"this323Is434A567Line323Break"];
  while ([string rangeOfString:magicString].length != 0) {
    [magicString appendString:@"g"];
  }
  [string setString:[[string componentsSeparatedByString:@"\r\n"]
                                  componentsJoinedByString:magicString]];
  [string setString:[[string componentsSeparatedByString:@"\r"]
                                  componentsJoinedByString:magicString]];
  [string setString:[[string componentsSeparatedByString:@"\n"]
                             componentsJoinedByString:magicString]];
  [string setString:[[string componentsSeparatedByString:magicString]
                             componentsJoinedByString:@"\r\n"]];
  [magicString release];
  [pool release];
  return string;
}

/*
 Returns... 1 for UNIX, 2 for Mac, 3 for DOS
 */
+(int)detectLBFormat:(NSString*)string {
  int i;
  int stringLength = [string length];
  unichar unixLB = [@"\n" characterAtIndex:0];
  unichar macLB = [@"\r" characterAtIndex:0];
  unichar currentChar;
  for (i = 0; i < stringLength; i++) {
    currentChar = [string characterAtIndex:i];
    if (currentChar == macLB) {
      if ((i + 1) < stringLength) {
        if ([string characterAtIndex:(i + 1)] == unixLB) {
          return 3;
        }
        else {
          return 2;
        }
      }
      else {
        return 2;
      }
    }
  }
  return 1;
}

+(BOOL)isEntityEscapedAtRange:(NSRange)range inString:(NSString*)string {
  int escapeNumber = 0;
  int escIndex = range.location - 1;
  while (escIndex >= 0) {
    if ([string characterAtIndex:escIndex] == '\\') {
      escapeNumber += 1;
    }
    else {
      break;
    }
    escIndex -= 1;
  }
  return ((escapeNumber % 2) == 1);
}

@end
