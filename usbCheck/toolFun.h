//
//  toolFun.h
//  qt_simulator
//
//  Created by diags on 3/11/10.
//  Copyright 2010 Foxconn. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ToolFun : NSObject {

}
//tool funcrion
+(NSString*)getStrFromPrefixAndPostfix:(NSString*)strSource Prefix:(NSString*)strPrefix Postfix:(NSString*)strPostfix ;
+(NSString*)getStrToEndString:(NSString*)strSource EndString:(NSString*)strEndString Option:(bool)isContainEndString ;
+(NSString*)getStrFromLen:(NSString*)strSource length:(int)truncateLen Option:(bool)bDirection ;

+(NSString*)clearCommentFromStr:(NSString*) strSource ;
+(NSString*)clearCommentFromPlistStr:(NSString*)strSource ;


+(NSString*)allTrimFromString:(NSString*)strSource trimStr:(NSString*)charSet leftTrim:(bool)bLf rightTrim:(bool)bRG ;
+(NSString*)deleteFromString:(NSString*)strSource trimStr:(NSString*)charSet ;
+(NSString*)deleteToPostfix:(NSString*)strSource EndString:(NSString*)charSet Option:(bool)isContainEndString ;


+(NSString*)getCurrentDateTime ;//format defined: yyyymmddhhmmss  
+(NSString*)GetSubStrFrom:(NSString* ) sourcestr
			   BetweenStr:(NSString* ) BeginStr
				ANDSymbol:( NSString* ) symbol;


//translate yyyymmddhhmmss to International format (YYYY-MM-DD HH:MM:SS  HHMM).
+(NSString*)getInternationalStr:(NSString*)strSource offset:(NSString*)strOffset;
+(bool)isNumber:(NSString*)strParm;

+(NSInteger)ConvertHexStrToInt:(NSString *)strParm; //no have 0x title.

// serin 2010-04-05
+(NSString*)ConvertDecimalStrToHexStr:(NSString*)strDec;

//Note:the function is case sensitive
+(int)numberOfOccurrences:(NSString*)strSource searchStr:(NSString*)substr;

//caijunbo 2010-06-30
+(NSMutableArray*)sortArrayWithIntObj:(NSMutableArray*)array;

//print 2D Barcode with input string
+(BOOL)print2DBarcode:(NSString*)barcode ;
@end
