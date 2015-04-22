//
//  toolFun.m
//  qt_simulator
//
//  Created by diags on 3/11/10.
//  Copyright 2010 Foxconn. All rights reserved.
//

#import "toolFun.h"


@implementation ToolFun
//tool funcrion
+(NSString*)getStrFromPrefixAndPostfix:(NSString*)strSource Prefix:(NSString*)strPrefix Postfix:(NSString*)strPostfix
{
	if (strSource==nil)
		return nil ;
	
	if (strPrefix==nil && strPostfix==nil)
		return strSource ;
	
	NSRange rangPrefix,rangPostfix ;
	if (strPrefix==nil)
	{
		rangPostfix = [strSource rangeOfString:strPostfix] ;
		if (rangPostfix.length <= 0)
			return nil ;
		else
			return [strSource substringToIndex:rangPostfix.location] ;
	}else if(strPostfix==nil)
	{
		rangPrefix = [strSource rangeOfString:strPrefix] ;
		if (rangPrefix.length <= 0)
			return nil ;
		else
			return [strSource substringFromIndex:rangPrefix.location+rangPrefix.length] ;
	}else
	{
		rangPrefix = [strSource rangeOfString:strPrefix] ;
		if (rangPrefix.length > 0)
		{
			rangPostfix = [[strSource substringFromIndex:rangPrefix.location+rangPrefix.length] rangeOfString:strPostfix] ;
			if (rangPostfix.length > 0)
				rangPostfix.location = rangPostfix.location + rangPrefix.location+rangPrefix.length ;
		}else
		{
			rangPostfix.location = NSNotFound ;
			rangPostfix.length = 0 ;
		}
		
		if (rangPrefix.length <= 0 ||
			rangPostfix.length <= 0 ||
			rangPrefix.location>rangPostfix.location
			)
			return nil ;
		else
		{
			NSRange rangTmp ;
			rangTmp.location = rangPrefix.location+rangPrefix.length ;
			rangTmp.length = rangPostfix.location - rangTmp.location ;
			return [strSource substringWithRange:rangTmp] ;
		};
		
	}
}

+(NSString*)getStrToEndString:(NSString*)strSource EndString:(NSString*)strEndString Option:(bool)isContainEndString
{
	if (strSource==nil)
		return nil ;
	if (strEndString==nil)
		return strSource ;
	
	NSRange rangTmp = [strSource rangeOfString:strEndString];
	if (rangTmp.length <= 0)
		return nil ;
	else
	{
		if (isContainEndString)
			return [strSource substringToIndex:rangTmp.location+rangTmp.length] ;
		else
			return [strSource substringToIndex:rangTmp.location] ;
	}
}

+(NSString*)getStrFromLen:(NSString*)strSource length:(int)truncateLen Option:(bool)bDirection 
{
	if (strSource==nil)
		return nil ;
	if ([strSource length]<=truncateLen)
		return strSource ;
	
	if (bDirection) //truncate str from front 
		return [strSource substringToIndex:truncateLen] ;
	else
		return [strSource substringFromIndex:[strSource length]-truncateLen] ;
	
}

+(NSString*)clearCommentFromStr:(NSString*)strSource
{
	if (strSource==nil)
		return nil ;
	NSMutableString *mutStrTmp = [[[NSMutableString alloc] initWithString:strSource] autorelease] ;
	NSRange rangPrefix,rangPostfix,rangClear ;
	
	//clear character '//'
	rangPrefix = [mutStrTmp rangeOfString:@"//"] ;
	while (rangPrefix.length > 0) //exist  first character "*/"
	{
		NSString *strTmp = [mutStrTmp substringFromIndex:rangPrefix.location] ;
		if (strTmp==nil)
			return nil ; //clear Comment occur error ,return nil ;
		
		rangPostfix = [strTmp rangeOfString:@"\n"] ;
		if (rangPostfix.length <= 0)
		{
			rangClear.location = rangPrefix.location ;
			rangClear.length = [strTmp length] ;
		}else
		{
			rangClear.location = rangPrefix.location ;
			rangClear.length = rangPostfix.location ;//+rangPostfix.length ;
		}
		[mutStrTmp deleteCharactersInRange:rangClear];
		
		rangPrefix = [mutStrTmp rangeOfString:@"//"] ;
	}
	
	//clear Character '/* */'
	rangPostfix = [mutStrTmp rangeOfString:@"*/"] ;
	while (rangPostfix.length > 0) //exist  first character "*/"
	{
		NSString *strTmp = [mutStrTmp substringToIndex:rangPostfix.location+rangPostfix.length] ;
		if (strTmp==nil)
			return nil ; //clear Comment occur error ,return nil ;
		rangPrefix = [strTmp rangeOfString:@"/*" options:NSBackwardsSearch] ;
		if (rangPrefix.length <= 0)
			return nil ; //clear Comment occur error ,return nil ;
		
		//clear the time /*---*/
		rangClear.location = rangPrefix.location ;
		rangClear.length = rangPostfix.location+rangPostfix.length -rangClear.location ;
		[mutStrTmp deleteCharactersInRange:rangClear];
		
		rangPostfix = [mutStrTmp rangeOfString:@"*/"] ;
	}
	rangPrefix = [mutStrTmp rangeOfString:@"/*"] ;
	if (rangPrefix.length > 0)
		return nil ;
	
	return mutStrTmp ;
}

+(NSString*)clearCommentFromPlistStr:(NSString*)strSource
{
	if (strSource==nil)
		return nil ;
	NSMutableString *mutStrTmp = [[[NSMutableString alloc] initWithString:strSource] autorelease] ;
	NSRange rangPrefix,rangPostfix,rangClear ;
	
	//clear Character '<!-- -->'
	rangPostfix = [mutStrTmp rangeOfString:@"-->"] ;
	while (rangPostfix.length > 0) //exist  first character "*/"
	{
		NSString *strTmp = [mutStrTmp substringToIndex:rangPostfix.location+rangPostfix.length] ;
		if (strTmp==nil)
			return nil ; //clear Comment occur error ,return nil ;
		rangPrefix = [strTmp rangeOfString:@"<!--" options:NSBackwardsSearch] ;
		if (rangPrefix.length <= 0)
			return nil ; //clear Comment occur error ,return nil ;
		
		//clear the time /*---*/
		rangClear.location = rangPrefix.location ;
		rangClear.length = rangPostfix.location+rangPostfix.length -rangClear.location ;
		[mutStrTmp deleteCharactersInRange:rangClear];
		
		rangPostfix = [mutStrTmp rangeOfString:@"-->"] ;
	}
	rangPrefix = [mutStrTmp rangeOfString:@"<!--"] ;
	if (rangPrefix.length > 0)
		return nil ;
	
	return mutStrTmp ;
}


+(NSString*)allTrimFromString:(NSString*)strSource trimStr:(NSString*)charSet leftTrim:(bool)bLf rightTrim:(bool)bRG
{
	if (strSource==nil)
		return nil ;
	if (charSet==nil)
		return strSource ;
	
	if (bLf==false && bRG==false)
		return strSource ;
	
	NSRange rangTmp ;
	NSMutableString *mutStrTmp = [NSMutableString stringWithString:strSource] ;
	rangTmp = [mutStrTmp rangeOfString:charSet] ; // SERACH FROM FRONR .
	while (rangTmp.location==0 && bLf)
	{
		[mutStrTmp deleteCharactersInRange:rangTmp] ;
		rangTmp = [mutStrTmp rangeOfString:charSet] ;
	}
	
	rangTmp = [mutStrTmp rangeOfString:charSet options:NSBackwardsSearch] ; // SERACH FROM backward .
	while ((rangTmp.location+rangTmp.length)==[mutStrTmp length] && bRG)
	{
		[mutStrTmp deleteCharactersInRange:rangTmp] ;
		rangTmp = [mutStrTmp rangeOfString:charSet options:NSBackwardsSearch] ;
	}
	
	return mutStrTmp ;
}

+(NSString*)deleteFromString:(NSString*)strSource trimStr:(NSString*)charSet
{
	if (strSource==nil)
		return nil ;
	if (charSet==nil)
		return strSource ;
	
	NSRange rangTmp ;
	NSMutableString *mutStrTmp = [[[NSMutableString alloc] initWithString:strSource] autorelease];
	rangTmp = [mutStrTmp rangeOfString:charSet] ; // SERACH FROM FRONR .
	while (rangTmp.length > 0)
	{
		[mutStrTmp deleteCharactersInRange:rangTmp] ;
		rangTmp = [mutStrTmp rangeOfString:charSet] ;
	}
	return mutStrTmp ;	
}

+(NSString*)deleteToPostfix:(NSString*)strSource EndString:(NSString*)charSet Option:(bool)isContainEndString
{
	if (strSource==nil)
		return nil ;
	if (charSet==nil)
		return strSource ;
	
	NSRange rangTmp ;
	NSMutableString *mutStrTmp = [[[NSMutableString alloc] initWithString:strSource] autorelease];
	rangTmp = [mutStrTmp rangeOfString:charSet] ; // SERACH FROM FRONR .
	if (rangTmp.length > 0)
	{
		if (isContainEndString)
			rangTmp.length = rangTmp.location+rangTmp.length ;
		rangTmp.location =0 ;
		[mutStrTmp deleteCharactersInRange:rangTmp] ;
	}
	return mutStrTmp ;	
	
}

+(NSString*)getCurrentDateTime //format defined: yyyymmddhhmmss  
{
	NSString* strTmp = [[NSDate date] description] ;
	strTmp = [self deleteFromString:strTmp trimStr:@"-"];
	strTmp = [self deleteFromString:strTmp trimStr:@":"];
	strTmp = [self deleteFromString:strTmp trimStr:@"+"];
	strTmp = [self deleteFromString:strTmp trimStr:@" "];
	
	//NSLog(@"\n %@ \n",strTmp) ;
	return [strTmp substringToIndex:14] ;
}
+(NSString*)GetSubStrFrom:(NSString* ) sourcestr
			   BetweenStr:(NSString* ) BeginStr
				ANDSymbol:( NSString* ) symbol 
{
	
	NSString* ret = [[[NSString alloc] init]autorelease];
	NSRange rg = [sourcestr rangeOfString:BeginStr];
	if(!rg.length>0)
		return ret;
	NSString* SubStr = [sourcestr substringFromIndex:rg.location + rg.length];
	NSRange rgsymbol = [SubStr rangeOfString:symbol];
	
	if(!rgsymbol.length>0)
		return ret;
	
	ret = [SubStr substringToIndex
		   :rgsymbol.location];
	return ret;
}//Kingking  

+(NSString*)getInternationalStr:(NSString*)strSource offset:(NSString*)strOffset
{
	if ([strSource length]!=14||strOffset==nil)
	{	
		return nil;
	}
	NSRange range;
	NSString *strYear		= nil;
	NSString *strMonth		= nil;
	NSString *strDay		= nil;
	NSString *strHour		= nil;
	NSString *strMinute		= nil;
	NSString *strSecond		= nil;
	NSString *strDest		= nil;
	
	range.location			= 0;
	range.length			= 4;
	strYear					= [strSource substringWithRange:range];
	strYear					= [strYear stringByAppendingString:@"-"];
	
	range.location			= 4;
	range.length			= 2;
	strMonth				= [strSource substringWithRange:range];
	strMonth				= [strMonth stringByAppendingString:@"-"];
	
	range.location			= 6;
	range.length			= 2;
	strDay					= [strSource substringWithRange:range];
	strDay					= [strDay stringByAppendingString:@" "];
	
	range.location			= 8;
	range.length			= 2;
	strHour					= [strSource substringWithRange:range];
	strHour					= [strHour stringByAppendingString:@":"];
	
	range.location			= 10;
	range.length			= 2;
	strMinute				= [strSource substringWithRange:range];
	strMinute				= [strMinute stringByAppendingString:@":"];
	
	range.location			= 12;
	range.length			= 2;
	strSecond				= [strSource substringWithRange:range];
	strSecond				= [strSecond stringByAppendingString:@" "];
	
	
	
	strDest					= [strYear stringByAppendingString:strMonth];
	strDest					= [strDest stringByAppendingString:strDay];
	strDest					= [strDest stringByAppendingString:strHour];
	strDest					= [strDest stringByAppendingString:strMinute];
	strDest					= [strDest stringByAppendingString:strSecond];
	strDest					= [strDest stringByAppendingString:strOffset];
	
	return strDest;
	
	//translate end
	
}

+(bool)isNumber:(NSString*)strParm
{
	if (strParm==nil)
		return false ;
	
	NSString *strTmp = [self allTrimFromString:strParm trimStr:@" " leftTrim:true rightTrim:true] ;
	if ([strTmp length]>30)
		return false ;
	
	NSRange rangeTmp;
	rangeTmp.length=1 ;
	
	int iCount=0 ;
	
	for(int i=0 ;i<[strTmp length] ;i++)
	{
		rangeTmp.location = i ;
		NSString *strTmp1 = [strTmp substringWithRange:rangeTmp] ;
		
		if (i==0 && [strTmp1 isEqualToString:@"."])
			return false ;
		if (i==([strTmp length]-1) && [strTmp1 isEqualToString:@"."])
			return false ;
		
		if (iCount>1)
			return FALSE ;
		
		if ([strTmp1 isEqualToString:@"0"] || [strTmp1 isEqualToString:@"1"] ||
			[strTmp1 isEqualToString:@"2"] || [strTmp1 isEqualToString:@"3"] ||
			[strTmp1 isEqualToString:@"4"] || [strTmp1 isEqualToString:@"5"] ||
			[strTmp1 isEqualToString:@"6"] || [strTmp1 isEqualToString:@"7"] ||
			[strTmp1 isEqualToString:@"8"] || [strTmp1 isEqualToString:@"9"] 
			)
			continue ;
		else if([strTmp1 isEqualToString:@"."])
			iCount++ ;
		else
			return false ;
	}
	
	return true ;
};

+(NSInteger)ConvertHexStrToInt:(NSString *)strParm
{
	if (strParm==nil)
		return 0 ;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init] ;

	NSString* strTmp=[self getStrFromLen:strParm length:2 Option:true] ;
	NSString* strHandle = [NSString stringWithString:strParm] ;
	 if ([strTmp isEqualToString:@"0x"] ||
		 [strTmp isEqualToString:@"0X"]
		 )
	 {
		 NSRange rangeTmp;
		 rangeTmp.location=2 ;
		 rangeTmp.length = [strParm length]-2 ;
		 strHandle = [strParm substringWithRange:rangeTmp] ;
	 }
	
	if ([strHandle length]<1)
		return 0;
	//handle hex
	
	NSRange rangeTmp;
	NSString *strResult= [NSString stringWithString:@"0"] ;
	
	for(int i=0 ;i<[strHandle length] ;i++)
	{
		rangeTmp.location = i;
		rangeTmp.length = 1;
		NSString *strCut = [strHandle substringWithRange:rangeTmp] ;
		int iTmp=0 ,iTmp1=[strResult integerValue] ;
		if ([strCut isEqualToString:@"1"] || [strCut isEqualToString:@"2"] ||
			[strCut isEqualToString:@"3"] || [strCut isEqualToString:@"4"] ||
			[strCut isEqualToString:@"3"] || [strCut isEqualToString:@"5"] ||
			[strCut isEqualToString:@"6"] || [strCut isEqualToString:@"7"] ||
			[strCut isEqualToString:@"8"] || [strCut isEqualToString:@"9"] ||
			[strCut isEqualToString:@"0"]
			)
		{
			iTmp = [strCut intValue] ;
			for(int j=1 ;j<([strHandle length] -i) ;j++)
				iTmp*=16 ;
			iTmp1+=iTmp ;
		}else if ([strCut isEqualToString:@"a"] || [strCut isEqualToString:@"A"])
		{
			iTmp = 10 ;
			for(int j=1 ;j<([strHandle length] -i) ;j++)
				iTmp*=16 ;
			iTmp1+=iTmp ;
		}else if ([strCut isEqualToString:@"b"] || [strCut isEqualToString:@"B"])
		{
			iTmp = 11 ;
			for(int j=1 ;j<([strHandle length] -i) ;j++)
				iTmp*=16 ;
			iTmp1+=iTmp ;
		}else if ([strCut isEqualToString:@"c"] || [strCut isEqualToString:@"C"])
		{
			iTmp = 12 ;
			for(int j=1 ;j<([strHandle length] -i) ;j++)
				iTmp*=16 ;
			iTmp1+=iTmp ;
		}else if ([strCut isEqualToString:@"d"] || [strCut isEqualToString:@"D"])
		{
			iTmp = 13 ;
			for(int j=1 ;j<([strHandle length] -i) ;j++)
				iTmp*=16 ;
			iTmp1+=iTmp ;
		}else if ([strCut isEqualToString:@"e"] || [strCut isEqualToString:@"E"])
		{
			iTmp = 14 ;
			for(int j=1 ;j<([strHandle length] -i) ;j++)
				iTmp*=16 ;
			iTmp1+=iTmp ;
		}else if ([strCut isEqualToString:@"f"] || [strCut isEqualToString:@"F"])
		{
			iTmp = 15 ;
			for(int j=1 ;j<([strHandle length] -i) ;j++)
				iTmp*=16 ;
			iTmp1+=iTmp ;
		}else // 
		{
			[pool release] ;
			return 0 ;
		}
			
		strResult = [NSString stringWithFormat:@"%d",iTmp1] ;
	}
	NSInteger intResult =[strResult integerValue] ; 
	[pool release] ;
	return intResult ;
	
}


// serin 2010-04-06
+(NSString*)ConvertDecimalStrToHexStr:(NSString*)strDec
{
	return [ NSString stringWithFormat:@"%02x",[strDec integerValue] ];
}

+(int)numberOfOccurrences:(NSString*)strSource searchStr:(NSString*)substr
{
	if (substr==nil || strSource==nil)
	{
		return -1;
	}
	
	int icount = 0;
	NSRange range;
	NSString *strTemp;
	strTemp = [NSString stringWithString:strSource];
	range   = [strTemp rangeOfString:substr];
	while (range.length > 0)
	{
		icount ++ ;
		strTemp = [strTemp substringFromIndex:(range.location+range.length)];
		range   = [strTemp rangeOfString:substr];
	}
	
	return icount;
	
}


//caijunbo 2010-06-30

+(NSMutableArray*)sortArrayWithIntObj:(NSMutableArray*)array

{
	NSMutableArray* temparray=[NSMutableArray arrayWithArray:array];
	int isize=[temparray count];
	if (isize<=1)
		return array;
	
	for(int i=isize-1;i>0;i--)
	{
		for(int j=0;j<i;j++)
		{
			int itemp;
			if([[temparray objectAtIndex:j] intValue]<[[temparray objectAtIndex:(j+1)] intValue])
			{
				itemp=[[temparray objectAtIndex:j] intValue];
				[temparray replaceObjectAtIndex:j withObject:[temparray objectAtIndex:(j+1)]];
				[temparray replaceObjectAtIndex:(j+1) withObject:[NSNumber numberWithInt:itemp]];
			}
			
		}
		
	}
	
	return temparray;
	
	
}

+(BOOL)print2DBarcode:(NSString*)barcode
{
    if (barcode==nil || [barcode length]==0)
        return FALSE ;
    
    NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0.0, 0.0, 215.0, 22.0)] ;
    if (textField==nil)
        return FALSE ;
    [textField setStringValue:barcode] ;
    NSPrintOperation *printOpern = [NSPrintOperation printOperationWithView:textField] ;
    BOOL rtn ;
    
    rtn = [printOpern runOperation] ;
    [textField release] ;
    return rtn ;
}

@end
