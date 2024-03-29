/*
 * Name: OGReplaceExpression.h
 * Project: OgreKit
 *
 * Creation Date: Sep 22 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#import <OgreKit/OGRegularExpression.h>

@class OGRegularExpressionMatch;

extern NSString	* const OgreReplaceException;

@interface OGReplaceExpression : NSObject <NSCopying, NSCoding>
{
	NSMutableArray	*_compiledReplaceString;
	NSMutableArray	*_nameArray;
}

/*********
 * 初期化 *
 *********/
/*
 expressionString中では次の特殊文字が使用できる。
  \&, \0		マッチした文字列
  \1 ... \9		n番目の括弧の内容
  \+			最後の括弧に対応する文字列
  \`			マッチした部分より前の文字列 (prematchString)
  \'			マッチした部分より後ろの文字列 (postmatchString)
  \-			最後にマッチした部分と、一つ前にマッチした部分の間の文字列 (stringBetweenLastMatchAndLastButOneMatch)
  \g<name>  	(?<name>...)にマッチした部分文字列 (OgreCaptureGroupOptionを指定した場合に使用可能)
  \g<index> 	index番目に(...)か(?<name>...)にマッチした部分文字列 (OgreCaptureGroupOptionを指定した場合に使用可能)
  \\			バックスラッシュ "\"
  \t			水平タブ (0x09)
  \n			改行 (0x0A)
  \r			復帰 (0x0D)
  \x{HHHH}		16-bit Unicode character U+HHHH
  \その他の文字	\その他の文字
 */
- (id)initWithString:(NSString*)replaceString syntax:(OgreSyntax)syntax escapeCharacter:(NSString*)character;
- (id)initWithString:(NSString*)replaceString escapeCharacter:(NSString*)character;
- (id)initWithString:(NSString*)replaceString;

+ (id)replaceExpressionWithString:(NSString*)replaceString syntax:(OgreSyntax)syntax escapeCharacter:(NSString*)character;
+ (id)replaceExpressionWithString:(NSString*)replaceString escapeCharacter:(NSString*)character;
+ (id)replaceExpressionWithString:(NSString*)replaceString;

/*******
 * 置換 *
 *******/
- (NSString*)replaceMatchedStringOf:(OGRegularExpressionMatch*)match;

@end
