/*
 * Name: OGRegularExpressionMatch.h
 * Project: OgreKit
 *
 * Creation Date: Aug 30 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#ifndef NOT_RUBY
#	define NOT_RUBY
#endif
#ifndef HAVE_CONFIG_H
#	define HAVE_CONFIG_H
#endif
#import <OgreKit/oniguruma.h>


// constants
extern NSString	* const OgreMatchException;


@class OGRegularExpression, OGRegularExpressionEnumerator;

@interface OGRegularExpressionMatch : NSObject <NSCopying, NSCoding>
{
	OnigRegion		*_region;						// match result region
	OGRegularExpressionEnumerator*	_enumerator;	// 生成主
	unsigned		_locationCache;					// 既に分かっているNSStringの長さとUTF8Stringの長さの対応
	unsigned		_utf8LocationCache;				// 
	unsigned		_utf8TerminalOfLastMatch;		// 前回にマッチした文字列の終端位置 (_region->end[0])
	
	NSString		*_swappedTargetString;			// 検索対象文字列。\が入れ替わっている(ことがある)ので注意
	unsigned char	*_utf8SwappedTargetString;		// UTF8での検索対象文字列
	NSRange			_searchRange;					// 検索範囲
	NSString		*_escapeCharacter;				// \の代替文字
	unsigned		_index;							// マッチした順番
	OGRegularExpressionMatch	*_parentMatch;		// 生成主のOGRegularExpressionMatchオブジェクト
}

/*********
 * 諸情報 *
 *********/
// マッチした順番 0,1,2,...
- (unsigned)index;

// 部分文字列の数 + 1
- (unsigned)count;

// description
- (NSString*)description;


/*********
 * 文字列 *
 *********/
// マッチの対象になった文字列
- (NSString*)targetString;

// マッチした文字列 \&, \0
- (NSString*)matchedString;

// index番目のsubstring \index
//  index番目のsubstringが存在しない時には nil を返す。
- (NSString*)substringAtIndex:(unsigned)index;

// マッチした部分より前の文字列 \`
- (NSString*)prematchString;

// マッチした部分より後ろの文字列 \'
- (NSString*)postmatchString;

// 最後にマッチした部分文字列 \+
// 存在しないときには nil を返す。
- (NSString*)lastMatchSubstring;

// マッチした部分と一つ前にマッチした部分の間の文字列 \- (独自に追加)
- (NSString*)stringBetweenMatchAndLastMatch;


/*******
 * 範囲 *
 *******/
// マッチした文字列の範囲
- (NSRange)rangeOfMatchedString;

// index番目のsubstringの範囲
//  index番目のsubstringが存在しない時には {-1, 0} を返す。
- (NSRange)rangeOfSubstringAtIndex:(unsigned)index;

// マッチした部分より前の文字列の範囲
- (NSRange)rangeOfPrematchString;

// マッチした部分より後ろの文字列の範囲
- (NSRange)rangeOfPostmatchString;

// 最後にマッチした部分文字列の範囲
// 存在しないときには {-1,0} を返す。
- (NSRange)rangeOfLastMatchSubstring;

// マッチした部分と一つ前にマッチした部分の間の文字列の範囲
- (NSRange)rangeOfStringBetweenMatchAndLastMatch;


/***************************************************************
 * named group関連 (OgreCaptureGroupOptionを指定したときに使用可能) *
 ***************************************************************/
// 名前(ラベル)がnameの部分文字列
// 存在しない名前の場合は nil を返す。
// 同一の名前を持つ部分文字列が複数ある場合は例外を発生させる。
- (NSString*)substringNamed:(NSString*)name;

// 名前がnameの部分文字列の範囲
// 存在しない名前の場合は {-1, 0} を返す。
// 同一の名前を持つ部分文字列が複数ある場合は例外を発生させる。
- (NSRange)rangeOfSubstringNamed:(NSString*)name;

// 名前がnameの部分文字列のindex
// 存在しない名前の場合は -1 を返す。
// 同一の名前を持つ部分文字列が複数ある場合は例外を発生させる。
- (unsigned)indexOfSubstringNamed:(NSString*)name;

// index番目の部分文字列の名前
// 存在しない名前の場合は nil を返す。
- (NSString*)nameOfSubstringAtIndex:(unsigned)index;

/***********************
* マッチした部分文字列を得る *
************************/
// (regex1)|(regex2)|... のような正規表現で、どのregex*にマッチしたかによって条件分岐する場合に便利。
/* 使用例: 
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:@"([0-9]+)|([a-zA-Z]+)"];
	NSEnumerator	*matchEnum = [regex matchEnumeratorInString:@"123abc"];
	OGRegularExpressionMatch	*match;
	while ((match = [matchEnum nextObject]) != nil) {
		switch ([match indexOfFirstMatchedSubstring]) {
			case 1:
				NSLog(@"numbers");
				break;
			case 2:
				NSLog(@"alphabets");
				break;
		}
	}
*/
// マッチした部分文字列のうちグループ番号が最小のもの (ない場合は0を返す)
- (unsigned)indexOfFirstMatchedSubstring;
- (unsigned)indexOfFirstMatchedSubstringBeforeIndex:(unsigned)anIndex;
- (unsigned)indexOfFirstMatchedSubstringAfterIndex:(unsigned)anIndex;
- (unsigned)indexOfFirstMatchedSubstringInRange:(NSRange)aRange;
// その名前
- (NSString*)nameOfFirstMatchedSubstring;
- (NSString*)nameOfFirstMatchedSubstringBeforeIndex:(unsigned)anIndex;
- (NSString*)nameOfFirstMatchedSubstringAfterIndex:(unsigned)anIndex;
- (NSString*)nameOfFirstMatchedSubstringInRange:(NSRange)aRange;

// マッチした部分文字列のうちグループ番号が最大のもの (ない場合は0を返す)
- (unsigned)indexOfLastMatchedSubstring;
- (unsigned)indexOfLastMatchedSubstringBeforeIndex:(unsigned)anIndex;
- (unsigned)indexOfLastMatchedSubstringAfterIndex:(unsigned)anIndex;
- (unsigned)indexOfLastMatchedSubstringInRange:(NSRange)aRange;
// その名前
- (NSString*)nameOfLastMatchedSubstring;
- (NSString*)nameOfLastMatchedSubstringBeforeIndex:(unsigned)anIndex;
- (NSString*)nameOfLastMatchedSubstringAfterIndex:(unsigned)anIndex;
- (NSString*)nameOfLastMatchedSubstringInRange:(NSRange)aRange;

// マッチした部分文字列のうち最長のもの (ない場合は0を返す。同じ長さの物が複数あれば、番号の小さい物が優先される)
- (unsigned)indexOfLongestSubstring;
- (unsigned)indexOfLongestSubstringBeforeIndex:(unsigned)anIndex;
- (unsigned)indexOfLongestSubstringAfterIndex:(unsigned)anIndex;
- (unsigned)indexOfLongestSubstringInRange:(NSRange)aRange;
// その名前
- (NSString*)nameOfLongestSubstring;
- (NSString*)nameOfLongestSubstringBeforeIndex:(unsigned)anIndex;
- (NSString*)nameOfLongestSubstringAfterIndex:(unsigned)anIndex;
- (NSString*)nameOfLongestSubstringInRange:(NSRange)aRange;

// マッチした部分文字列のうち最短のもの (ない場合は0を返す。同じ長さの物が複数あれば、番号の小さい物が優先される)
- (unsigned)indexOfShortestSubstring;
- (unsigned)indexOfShortestSubstringBeforeIndex:(unsigned)anIndex;
- (unsigned)indexOfShortestSubstringAfterIndex:(unsigned)anIndex;
- (unsigned)indexOfShortestSubstringInRange:(NSRange)aRange;
// その名前
- (NSString*)nameOfShortestSubstring;
- (NSString*)nameOfShortestSubstringBeforeIndex:(unsigned)anIndex;
- (NSString*)nameOfShortestSubstringAfterIndex:(unsigned)anIndex;
- (NSString*)nameOfShortestSubstringInRange:(NSRange)aRange;

/******************
* Capture History *
*******************/
/*例:
	NSString					*target = @"abc de";
	OGRegularExpression			*regex = [OGRegularExpression regularExpressionWithString:@"(?@[a-z])+"];
	OGRegularExpressionMatch	*match, *capture;
	NSEnumerator				*matchEnumerator = [regex matchEnumeratorInString:target];
	unsigned					i;
	
	while ((match = [matchEnumerator nextObject]) != nil) {
		capture = [match captureHistoryAtIndex:1];
		NSLog(@"number of capture history: %d", [capture count]);
		for (i = 0; i < [capture count]; i++) NSLog(@" %@", [capture substringAtIndex:i]);
	}
	
ログ:
number of capture history: 3
 a
 b
 c
number of capture history: 2
 d
 e
 */

// index番目のグループの捕獲履歴
// 履歴がない場合はnilを返す。
- (OGRegularExpressionMatch*)captureHistoryAtIndex:(unsigned)index;

// 名前がnameのグループの捕獲履歴
// 履歴がない場合はnilを返す。
- (OGRegularExpressionMatch*)captureHistoryNamed:(NSString*)name;

@end

// UTF8文字列の長さを得る
inline unsigned Ogre_utf8strlen(unsigned char *const utf8string, unsigned char *const end);
