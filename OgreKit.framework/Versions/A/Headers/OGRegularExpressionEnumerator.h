/*
 * Name: OGRegularExpressionEnumerator.h
 * Project: OgreKit
 *
 * Creation Date: Sep 03 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>

@class OGRegularExpression;

// Exception
extern NSString	* const OgreEnumeratorException;

@interface OGRegularExpressionEnumerator : NSEnumerator <NSCopying, NSCoding>
{
	OGRegularExpression	*_regex;							// 正規表現オブジェクト
	NSString			*_swappedTargetString;				// 検索対象文字列。\が入れ替わっている(事がある)ので注意
	unsigned char		*_utf8SwappedTargetString;			// UTF8での検索対象文字列
	unsigned			_utf8lengthOfSwappedTargetString;	// strlen([_swappedTargetString UTF8String])
	NSRange				_searchRange;						// 検索範囲
	unsigned			_searchOptions;						// 検索オプション
	int					_utf8TerminalOfLastMatch;			// 前回にマッチした文字列の終端位置  (_region->end[0])
	unsigned			_startLocation;						// マッチ開始位置
	unsigned			_utf8StartLocation;					// UTF8でのマッチ開始位置
	BOOL				_isLastMatchEmpty;					// 前回のマッチが空文字列だったかどうか
	
	unsigned			_numberOfMatches;					// マッチした数
}

// 全マッチ結果を配列で返す。
- (NSArray*)allObjects;
// 次のマッチ結果を返す。
- (id)nextObject;

// description
- (NSString*)description;

@end
