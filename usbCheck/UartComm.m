//
//  UartComm.m
//  qt_simulator
//
//  Created by diags on 3/4/10.
//  Copyright 2010 Foxconn. All rights reserved.
//

#import "UartComm.h"
#import <IOKit/IOKitLib.h>
#import <IOKit/serial/IOSerialKeys.h>
#include <netdb.h>
#include <arpa/inet.h>
//#import "toolFun.h"

//Key define
NSString* const DeviceID ;

//custom define Notification
NSString* const MACOS_COMM_CONNECT_SUCCESS = @"MACOS_COMM_CONNECT_SUCCESS" ;     //obtain the device success
NSString* const MACOS_COMM_CONNECT_FAIL = @"MACOS_COMM_CONNECT_FAIL"   ;         //obtain the device fail
NSString* const MACOS_COMM_RECV_CHAR = @"MACOS_COMM_RECV_CHAR" ;                //notification for receive data
NSString* const MACOS_COMM_SEND_CHAR =@"MACOS_COMM_SEND_CHAR" ;                 //notification for send data ok
NSString* const MACOS_COMM_CONNECT_ABOUT =@"MACOS_COMM_CONNECT_ABOUT" ;         //notification for connect about

enum PortStatus
{
	PortStatus_Whether_Init             =0x00000001 ,
	PortStatus_Whether_FileDes          =0x00000002 ,
	PortStatus_Whether_Attribute_Success=0x00000008 ,
	PortStatus_Whether_Connect_Success  =0x00000020 , 
	PortStatus_Whether_StartThreadTurn  =0x00000080 ,
} ;

#define SET_BIT_1(x)    portStatus|=(x) 
#define SET_BIT_0(x)    portStatus&=~(x) 
#define GET_BIT(x)      portStatus&x  
//baudrate default

@implementation UartComm
-(id)init
{
	receDataBuffer = nil ;
	sendDataBuffer = nil ;
	fileDesc = 0 ;
	listenSocket=0;
	portID = nil ;
	UartCommThread = nil ;
	portStatus = 0X00000000 ;
	SET_BIT_0(PortStatus_Whether_Init|PortStatus_Whether_FileDes|PortStatus_Whether_StartThreadTurn|
			  PortStatus_Whether_Attribute_Success|PortStatus_Whether_Connect_Success);
    
    self=[super init] ;
	if (self)
	{
		receDataBuffer = [[NSMutableData alloc] init] ;
		sendDataBuffer = [[NSMutableData alloc] init] ;
		[receDataBuffer setLength:0] ;
		[sendDataBuffer setLength:0] ;
	    SET_BIT_1(PortStatus_Whether_Init);
	}
	return self ;
}

-(void)dealloc
{
	
	//[[NSNotificationCenter defaultCenter] removeObject:self] ;
	[receDataBuffer release] ;
	[sendDataBuffer release] ;
	[portID release] ;
	[UartCommThread release] ;
	[super dealloc] ;
}


-(bool)OpenPort:(NSString*)portName BaudRate
			   :(enum BaudRate)baudRate DataBits   
			   :(enum DataBits)dataBits StopBit
               :(enum StopBit)stopBit   Parity
			   :(enum Parity)parity     FlowControl
               :(enum FlowControl)flowControl 
{
	commType =TYPE_UART ;
    //clear old info start
	if (GET_BIT(PortStatus_Whether_FileDes)) 
	{
		close(fileDesc) ;
		SET_BIT_0(PortStatus_Whether_FileDes);
	}
   	//clear old info end
	
	SET_BIT_0(PortStatus_Whether_FileDes|PortStatus_Whether_StartThreadTurn|
			  PortStatus_Whether_Attribute_Success|PortStatus_Whether_Connect_Success);
	//parameter check 
	if (portName==nil)
		return false ;
	
	//filedesc configure 
	fileDesc = open([portName cStringUsingEncoding:NSASCIIStringEncoding],O_RDWR|O_NOCTTY|O_NDELAY|O_EXLOCK) ;

	if (fileDesc>0)
	{
		
		SET_BIT_1(PortStatus_Whether_FileDes);
		tcgetattr(fileDesc,&serialOption) ;
		serialOption.c_cc[VMIN] = 0 ;
		serialOption.c_cc[VTIME] = 1 ;
		serialOption.c_cflag |=(CLOCAL|CREAD) ;	
		//set define value
	    [self SetBaudRate:baudRate] ;
		[self SetParity:parity] ;
		[self SetStopBit:stopBit] ;
		[self SetDataBit:dataBits] ;
		[self SetFlowControl:flowControl];
		
		
		if (tcsetattr(fileDesc,TCSANOW,&serialOption)!=0 )
			return false ;
		SET_BIT_1(PortStatus_Whether_Attribute_Success);
		//create a thread
		if (UartCommThread!=nil)
		{
			[UartCommThread release] ;
			UartCommThread = nil ;
		};
		SET_BIT_1(PortStatus_Whether_Connect_Success|PortStatus_Whether_StartThreadTurn);
		
		//post a nofification to notification-center
		NSNotification *myNotification=nil ;
		if (portID==nil)
			myNotification = [[NSNotification notificationWithName:MACOS_COMM_CONNECT_SUCCESS object:self] retain] ;
		else
		{
			NSDictionary *nsdTmp = [[NSDictionary dictionaryWithObject:portID forKey:DeviceID] retain];
			myNotification = [[NSNotification notificationWithName:MACOS_COMM_CONNECT_SUCCESS object:self userInfo:nsdTmp] retain] ;
			[nsdTmp release];
		}
		
		[[NSNotificationCenter defaultCenter] postNotification:myNotification] ;
		[myNotification release] ;
		///end post notification 
		
		UartCommThread = [[NSThread alloc] initWithTarget:self selector:@selector(fileHandleThread) object:nil];
		[UartCommThread start] ;
		return true ;
	}
	return false ;
};


-(bool)IsOpen
{
	if (commType==TYPE_SOCKET)
		return [self Socket_IsOpen] ;
	else if (commType==TYPE_USBCLI)
        return true ;
	
	if (GET_BIT(PortStatus_Whether_Connect_Success))
		return true ;
	return false ;
};


-(void)ClosePort
{
	if (commType==TYPE_SOCKET)
	{
		[self Socket_ClosePort] ;
		return ;
	}else if (commType==TYPE_USBCLI)
        return ;
	
	if (GET_BIT(PortStatus_Whether_FileDes))
	{
		if (GET_BIT(PortStatus_Whether_StartThreadTurn))
		{
			SET_BIT_0(PortStatus_Whether_StartThreadTurn) ;
			[UartCommThread release] ;
			UartCommThread = nil ;
		}
		close(fileDesc) ;
		SET_BIT_0(PortStatus_Whether_FileDes) ;
		
		//post a nofification to notification-center
		NSNotification *myNotification=nil ;
		if (portID==nil)
			myNotification = [[NSNotification notificationWithName:MACOS_COMM_CONNECT_FAIL object:self] retain] ;
		else
		{
			NSDictionary *nsdTmp = [[NSDictionary dictionaryWithObject:portID forKey:DeviceID] retain];
			myNotification = [[NSNotification notificationWithName:MACOS_COMM_CONNECT_FAIL object:self userInfo:nsdTmp] retain ];
			[nsdTmp release];
		}
		
		[[NSNotificationCenter defaultCenter] postNotification:myNotification] ;
		[myNotification release] ;
		//END post a nofification to notification-center
	}
	
	
	SET_BIT_0(PortStatus_Whether_FileDes|PortStatus_Whether_StartThreadTurn|
			  PortStatus_Whether_Attribute_Success|PortStatus_Whether_Connect_Success);
	
	
};

-(void)SetBaudRate:(enum BaudRate)baudRate
{
	if (!(GET_BIT(PortStatus_Whether_FileDes)))
		return ;
	
	switch (baudRate) {
        case BAUDRATE_4800:
			cfsetispeed(&serialOption, B4800) ;
			cfsetospeed(&serialOption, B4800) ;
			break;
		case BAUDRATE_9600:
			cfsetispeed(&serialOption, B9600) ;
			cfsetospeed(&serialOption, B9600) ;
			break;
		case BAUDRATE_19200:
			cfsetispeed(&serialOption, B19200) ;
			cfsetospeed(&serialOption, B19200) ;
			break;
		case BAUDRATE_38400:
			cfsetispeed(&serialOption, B38400) ;
			cfsetospeed(&serialOption, B38400) ;
			break;
		case BAUDRATE_76800:
			cfsetispeed(&serialOption, B76800) ;
			cfsetospeed(&serialOption, B76800) ;
			break;
		case BAUDRATE_115200:
			cfsetispeed(&serialOption, B115200) ;
			cfsetospeed(&serialOption, B115200) ;
			break;
		case BAUDRATE_230400:
			cfsetispeed(&serialOption, B230400) ;
			cfsetospeed(&serialOption, B230400) ;
			break;
		default:
			break;
	}
	return;
};


-(void)SetDataBit:(enum DataBits)dataBits
{
	if (!(GET_BIT(PortStatus_Whether_FileDes)))
		return ;
	
    switch (dataBits) {
		case DATA_BITS_5:
			serialOption.c_cflag |=CS5 ;
			break;
		case DATA_BITS_6:
			serialOption.c_cflag |=CS6 ;
			break;	
		case DATA_BITS_7:
			serialOption.c_cflag |=CS7 ;
			break;
		case DATA_BITS_8:
			serialOption.c_cflag |=CS8 ;
			break;		
		default:
			break;
	}	
	return ;
};

-(void)SetParity:(enum Parity)parity
{
	if (!(GET_BIT(PortStatus_Whether_FileDes)))
		return ;
	
    switch (parity) {
		case PARITY_EVEN:
		case PARITY_ODD:
		case PARITY_NONE:
			serialOption.c_cflag &=~PARENB ;
			break;
		default:
			break;
	}	
	return ;		
};

-(void)SetStopBit:(enum StopBit)stopBit
{
	if (!(GET_BIT(PortStatus_Whether_FileDes)))
		return ;
	
    switch (stopBit) {
		case STOP_BITS_1:
		case STOP_BITS_2:
			serialOption.c_cflag &=~CSTOP ;
			break;
		default:
			break;
	}	
	return ;	
};


-(void)SetFlowControl:(enum FlowControl)flowControl
{
	if (!(GET_BIT(PortStatus_Whether_FileDes)))
		return ;

//#define CCTS_OFLOW	0x00010000	/* CTS flow control of output */
//#define CRTSCTS		(CCTS_OFLOW | CRTS_IFLOW)
//#define CRTS_IFLOW	0x00020000	/* RTS flow control of input */
//#define	CDTR_IFLOW	0x00040000	/* DTR flow control of input */
//#define CDSR_OFLOW	0x00080000	/* DSR flow control of output */
//#define	CCAR_OFLOW	0x00100000	/* DCD flow control of output */
    
	switch (flowControl) {
		case FLOW_CONTROL_HANDWARE:
            serialOption.c_cflag |=CDSR_OFLOW ;
            break ;
		case FLOW_CONTROL_SOFTWARE:
		case FLOW_CONTROL_NONE:	
			//serialOption.c_cflag &=~CSTOP ;|= CDTR_IFLOW;
//            serialOption.c_cflag |=CDTR_IFLOW ;
			break;
		default:
			break;
	}	
	return ;	
}


- (void)fileHandleThread
{	
	int wordsRead = 0;
	char tempRecBuffer[256] ;
	
	while (GET_BIT(PortStatus_Whether_StartThreadTurn))
	{
		NSAutoreleasePool *pool= [[NSAutoreleasePool alloc] init] ;
		memset(tempRecBuffer, 0, 256);
		wordsRead = read(fileDesc, tempRecBuffer, 255); 
		if (wordsRead>0) //read available data
		{
			[receDataBuffer appendBytes:tempRecBuffer length:wordsRead] ;
			
			//post a nofification to notification-center
			NSNotification *myNotification=nil ;
			if (portID==nil)
				myNotification = [[NSNotification notificationWithName:MACOS_COMM_RECV_CHAR object:self] retain] ;
			else
			{
				//NSDictionary *nsdTmp = [[NSDictionary dictionaryWithObject:portID forKey:DeviceID] retain];
				NSDictionary *nsdTmp = [[NSDictionary alloc] initWithObjectsAndKeys:portID,DeviceID,nil] ;
				myNotification = [[NSNotification notificationWithName:MACOS_COMM_RECV_CHAR object:self userInfo:nsdTmp] retain] ;
				[nsdTmp release];
			}
			
			[[NSNotificationCenter defaultCenter] postNotification:myNotification] ;
			[myNotification release] ;
			///end post notification 
		}else if(wordsRead<0)
		{
			//post a nofification to notification-center
			NSNotification *myNotification=nil ;
			if (portID==nil)
				myNotification = [[NSNotification notificationWithName:MACOS_COMM_CONNECT_ABOUT object:self] retain] ;
			else
			{
				NSDictionary *nsdTmp = [[NSDictionary dictionaryWithObject:portID forKey:DeviceID] retain];
				myNotification = [[NSNotification notificationWithName:MACOS_COMM_CONNECT_ABOUT object:self userInfo:nsdTmp] retain] ;
				[nsdTmp release];
			}
			
			[[NSNotificationCenter defaultCenter] postNotification:myNotification] ;
			[myNotification release] ;
			///end post notification 
			
			SET_BIT_0(PortStatus_Whether_StartThreadTurn|PortStatus_Whether_Connect_Success) ;
			[pool release] ;
			pool=nil ;
			break ;
		}else
		{
			usleep(100000) ; //delay 100 ms
		}
		[pool release] ;
		pool = nil ;
	}
	return ;
}

//send  and received data 
-(NSData*)ReceiveData
{
	if (commType==TYPE_SOCKET)
		return [self Socket_ReceiveData] ;
	else if (commType==TYPE_USBCLI)
        return [self USBCLI_ReceiveResult] ;
    
	NSData *myData = [[[NSData alloc] initWithBytes:[receDataBuffer bytes] length:[receDataBuffer length]] autorelease] ;
	//delete old buffer
	[receDataBuffer setLength:0] ;
	return myData ;
}

-(bool)SendData:(NSData*) sendBuffer
{
	if (commType==TYPE_SOCKET)
		return [self Socket_SendData:sendBuffer] ;
    else if (commType==TYPE_USBCLI)
    {
        return [self USBCLI_SendCmd:sendBuffer] ;
    }
	
	if (GET_BIT(PortStatus_Whether_Connect_Success))
	{
        //first to clear old buffer before sending cmd
        [receDataBuffer setLength:0];
		if (sendBuffer==nil)
			return true ;
#if 0
		int wordsWritten;
		char *cData= malloc([sendBuffer length] + 1) ;
		memset(cData,'\0',[sendBuffer length]+1) ;
		[sendBuffer getBytes:cData] ;
		wordsWritten = write(fileDesc, cData, [sendBuffer length]);
		free(cData);	
#else
        Byte *byte = (Byte *)sendBuffer.bytes ;
        for (int i=0; i<[sendBuffer length]; i++)
        {
            write(fileDesc, byte+i,1) ;
            usleep(1000*1) ;
        }
#endif
		//post a nofification to notification-center
		NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObject:sendBuffer forKey:@"SENDDATA"] ;
		if (portID!=nil)
			[d setValue:portID forKey:DeviceID] ;
		
		NSNotification *myNotification = [[NSNotification notificationWithName:MACOS_COMM_SEND_CHAR object:self userInfo:d] retain] ;
		[[NSNotificationCenter defaultCenter] postNotification:myNotification] ;
		[myNotification release] ;
		///end post notification 
		
		return true ;
	}
	return false ;
}

+(NSArray*)ScanPort
{
	io_iterator_t	serialPortIterator;
	CFMutableDictionaryRef classToMatch;
	io_object_t		serialService;
	kern_return_t	kernResult;
	char			bsdPath[255];
    
	NSMutableArray *mutableArray = [[[NSMutableArray alloc] init] autorelease] ;
	NSLog(@"run findSerialDevice ... ");
	// find serial serial port iterator
    
	classToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
	
	if(classToMatch == NULL){
		NSLog(@"IOServiceMatching return null dictionary.");
	} else {
		CFDictionarySetValue(classToMatch, CFSTR(kIOSerialBSDTypeKey), CFSTR(kIOSerialBSDRS232Type));
	}
	
	kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classToMatch, &serialPortIterator);
	
	if(KERN_SUCCESS != kernResult){
		NSLog(@"IOServiceGetMatchingServices returned %d \n", kernResult);
	}
	// get device path
	while ((serialService = IOIteratorNext(serialPortIterator)))
	{
		
		CFTypeRef	bsdPathAsCFString;
		
		bsdPathAsCFString = IORegistryEntryCreateCFProperty(serialService,
															CFSTR(kIOCalloutDeviceKey),
															kCFAllocatorDefault,
															0);
		if (bsdPathAsCFString)
		{
			Boolean result;
			
			result = CFStringGetCString(bsdPathAsCFString,
										bsdPath,
										255, 
										kCFStringEncodingUTF8);
			
			CFRelease(bsdPathAsCFString);
			
			if (result)
			{
				NSString *nsstrTmp = [[NSString alloc] initWithCString:bsdPath encoding:NSUTF8StringEncoding] ;
				NSRange range = [nsstrTmp rangeOfString:@"usbserial"] ;
				if (range.length > 0 )
				{
					[mutableArray addObject:nsstrTmp] ;
				}
				[nsstrTmp release] ;
				kernResult = KERN_SUCCESS;
			}
		}
		(void) IOObjectRelease(serialService);
	}			
	return mutableArray;
};

+(NSArray*)SCanUSBDevice 
{
#define kMyVendorID         1351
#define kMyProductID        8193
	io_iterator_t	usbPortIterator;
	CFMutableDictionaryRef classToMatch;
	io_object_t		usbService;
	kern_return_t	kernResult;
	char			bsdPath[255];
    CFNumberRef             numberRef;
    long                    usbVendor = kMyVendorID;
    
	NSMutableArray *mutableArray = [[[NSMutableArray alloc] init] autorelease] ;
	NSLog(@"run findSerialDevice ... ");
	// find usb port iterator
    
	classToMatch = IOServiceMatching(kIOUSBInterfaceClassName); //kIOSerialBSDServiceValue ,kIOUSBInterfaceClassName
	
	if(classToMatch == NULL){
		NSLog(@"IOServiceMatching return null dictionary.");
	} else
    {
#if 0
		CFDictionarySetValue(classToMatch, CFSTR(kIOSerialBSDTypeKey), CFSTR(kIOSerialBSDRS232Type));
        //CFDictionarySetValue(classToMatch, CFSTR("IOSerialBSDClientType"), CFSTR("fuck you yet")) ;
#else        
        numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbVendor);
        CFDictionarySetValue(classToMatch, 
                             CFSTR(kUSBVendorID), 
                             numberRef);
        CFRelease(numberRef);
#endif        
	} 
    NSLog(@"\n %@",classToMatch) ;
	kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classToMatch, &usbPortIterator);
	
	if(KERN_SUCCESS != kernResult){
		NSLog(@"IOServiceGetMatchingServices returned %d \n", kernResult);
	}
	// get device path
	while ((usbService = IOIteratorNext(usbPortIterator)))
	{
		
		CFTypeRef	bsdPathAsCFString;
		
		bsdPathAsCFString = IORegistryEntryCreateCFProperty(usbService,
															CFSTR(kIOCalloutDeviceKey),
															kCFAllocatorDefault,
															0);
		if (bsdPathAsCFString)
		{
			Boolean result;
			
			result = CFStringGetCString(bsdPathAsCFString,
										bsdPath,
										255, 
										kCFStringEncodingUTF8);
			
			CFRelease(bsdPathAsCFString);
			
			if (result)
			{
				NSString *nsstrTmp = [[NSString alloc] initWithCString:bsdPath encoding:NSUTF8StringEncoding] ;
				//NSRange range = [nsstrTmp rangeOfString:@"Bluetooth"] ;
				NSRange range = [nsstrTmp rangeOfString:@"usbserial"] ;
				if (range.length > 0 )
				{
					[mutableArray addObject:nsstrTmp] ;
				}
				[nsstrTmp release] ;
				kernResult = KERN_SUCCESS;
			}
		}
		(void) IOObjectRelease(usbService);
	}			
	return mutableArray;
}

+(BOOL) generateUSBSiblingsParaMeter
{
    NSBundle *bundle = [NSBundle mainBundle] ;
    NSString *strPath = [bundle resourcePath] ;
    
    if (strPath==nil)
        return FALSE ;
    
    NSString * CMDLine = [NSString stringWithFormat:@"%@/USBsiblings",strPath] ;//cmdLine 
    NSLog(@"USBSIBLING PATH=%@",CMDLine);
    CMDLine =[CMDLine stringByAppendingString:@" -t "];
    
    NSString *strDist = @"/" ;
    
    CMDLine =[CMDLine stringByAppendingString:strDist];
    //CMDLine =[CMDLine stringByAppendingString:@"/"];//findDevice.plist will be create here!
    
    NSLog(@"\n cmdline is :%@",CMDLine) ;
    system([CMDLine UTF8String]);
    
    //[self updateUSBAddrUsingSibling] ;
    return true;
}


+(NSArray*)ScanBaudRate 
{
	NSMutableArray *mutableArray = [[[NSMutableArray alloc] init] autorelease] ;
	[mutableArray addObject:@"9600"] ;
	[mutableArray addObject:@"19200"] ;
	[mutableArray addObject:@"38400"] ;
	[mutableArray addObject:@"76800"] ;
	[mutableArray addObject:@"115200"] ;
	[mutableArray addObject:@"230400"] ;
	return mutableArray ;
} ;

+(NSArray*)ScanDataBit
{
	NSMutableArray *mutableArray = [[[NSMutableArray alloc] init] autorelease] ;
	[mutableArray addObject:@"5"] ;
	[mutableArray addObject:@"6"] ;
	[mutableArray addObject:@"7"] ;
	[mutableArray addObject:@"8"] ;
	return mutableArray ;
	
} ;

+(NSArray*)ScanStopBit 
{
	NSMutableArray *mutableArray = [[[NSMutableArray alloc] init] autorelease] ;
	[mutableArray addObject:@"1"] ;
	[mutableArray addObject:@"2"] ;
	return mutableArray ;
};

+(NSArray*)ScanParity
{
	NSMutableArray *mutableArray = [[[NSMutableArray alloc] init] autorelease] ;
	[mutableArray addObject:@"EVEN"] ;
	[mutableArray addObject:@"ODD"] ;
	[mutableArray addObject:@"NONE"] ;
	return mutableArray ;
}

+(NSArray*)ScanFlowControl
{
	NSMutableArray *mutableArray = [[[NSMutableArray alloc] init] autorelease] ;
	[mutableArray addObject:@"HANDWARE"] ;
	[mutableArray addObject:@"SOFTWARE"] ;
	[mutableArray addObject:@"NONE"] ;
	return mutableArray ;
}

-(void)setPortID:(NSString*)nsstrTmp
{
	if (portID!=nil)
	{
		[portID release] ;
		portID = nil ;
	} ;
	portID = [[NSString alloc] initWithString:nsstrTmp] ;
	return  ;
	
}

///socket comm function as belowed 
-(bool)Socket_OpenPort:(NSString*)strIP PortID
                      :(int)iPortID 
{
	commType =TYPE_SOCKET ;
	if (GET_BIT(PortStatus_Whether_FileDes)) 
	{
		close(listenSocket) ;
		SET_BIT_0(PortStatus_Whether_FileDes);
	}
	
	SET_BIT_0(PortStatus_Whether_FileDes|PortStatus_Whether_StartThreadTurn|
			  PortStatus_Whether_Attribute_Success|PortStatus_Whether_Connect_Success);
	//parameter check 
	if (strIP==nil)
		return false ;
	
	if (iPortID>=65535 || iPortID<0)
		return FALSE ;
	
	////socket initializing as belowed
    struct protoent *ppe;
    ppe=getprotobyname("tcp");
    listenSocket=socket(AF_INET,SOCK_STREAM,ppe->p_proto);  ///----obtain  the socket handle .
    if (listenSocket==-1) //---obtain socket handle fail
		return false ;
    
	SET_BIT_1(PortStatus_Whether_FileDes);
    ///----connect operation as belowed
    struct sockaddr_in daddr;
    memset((void *)&daddr,0,sizeof(daddr));
    daddr.sin_family=AF_INET;
	daddr.sin_port=htons(iPortID);   ////convert port
    daddr.sin_addr.s_addr=inet_addr([strIP cStringUsingEncoding:NSASCIIStringEncoding]) ; ///connect address
	int err ;
    err = connect(listenSocket,(struct sockaddr *)&daddr,sizeof(daddr)) ;
	///....................................................
	if (err!=0) ///connected fail .
		return false;
	else
	{
		SET_BIT_1(PortStatus_Whether_Attribute_Success);
		//==configure port===============//
		int iTimeOut = 5000 ;
		setsockopt(listenSocket,IPPROTO_TCP,SO_RCVTIMEO,(char*)&iTimeOut,sizeof(int)) ;
		setsockopt(listenSocket,IPPROTO_TCP,SO_SNDTIMEO,(char*)&iTimeOut,sizeof(int)) ;
		int iAddr = 1 ;
		setsockopt(listenSocket,SOL_SOCKET,SO_REUSEADDR,(char*)&iAddr,sizeof(int)) ;
		//===============================//
		//create a listen socket for Socket communication.
		if (UartCommThread!=nil)
		{
			[UartCommThread release] ;
			UartCommThread = nil ;
		};
		SET_BIT_1(PortStatus_Whether_Connect_Success|PortStatus_Whether_StartThreadTurn);
		
		//post a nofification to notification-center
		NSNotification *myNotification=nil ;
		if (portID==nil)
			myNotification = [[NSNotification notificationWithName:MACOS_COMM_CONNECT_SUCCESS object:self] retain] ;
		else
		{
			NSDictionary *nsdTmp = [[NSDictionary dictionaryWithObject:portID forKey:DeviceID] retain];
			myNotification = [[NSNotification notificationWithName:MACOS_COMM_CONNECT_SUCCESS object:self userInfo:nsdTmp] retain] ;
			[nsdTmp release];
		}
		
		[[NSNotificationCenter defaultCenter] postNotification:myNotification] ;
		[myNotification release] ;
		///end post notification 
		
		UartCommThread = [[NSThread alloc] initWithTarget:self selector:@selector(Socket_fileHandleThread) object:nil];
		[UartCommThread start] ;
		return true ;		
	}
	
	return TRUE;
};

-(bool)Socket_IsOpen
{
	if (GET_BIT(PortStatus_Whether_Connect_Success))
		return true ;
	return false ;	
};

-(void)Socket_ClosePort
{
	if (GET_BIT(PortStatus_Whether_FileDes))
	{
		if (GET_BIT(PortStatus_Whether_StartThreadTurn))
		{
			SET_BIT_0(PortStatus_Whether_StartThreadTurn) ;
			[UartCommThread release] ;
			UartCommThread = nil ;
		}
		shutdown(listenSocket,3) ;////wait end the data sended.
		close(listenSocket);
		
		SET_BIT_0(PortStatus_Whether_FileDes) ;
		
		//post a nofification to notification-center
		NSNotification *myNotification=nil ;
		if (portID==nil)
			myNotification = [[NSNotification notificationWithName:MACOS_COMM_CONNECT_FAIL object:self] retain] ;
		else
		{
			NSDictionary *nsdTmp = [[NSDictionary dictionaryWithObject:portID forKey:DeviceID] retain];
			myNotification = [[NSNotification notificationWithName:MACOS_COMM_CONNECT_FAIL object:self userInfo:nsdTmp] retain ];
			[nsdTmp release];
		}
		
		[[NSNotificationCenter defaultCenter] postNotification:myNotification] ;
		[myNotification release] ;
		//END post a nofification to notification-center
	}
	
	
	SET_BIT_0(PortStatus_Whether_FileDes|PortStatus_Whether_StartThreadTurn|
			  PortStatus_Whether_Attribute_Success|PortStatus_Whether_Connect_Success);
	
}

-(NSData*)Socket_ReceiveData
{
	NSData *myData = [[[NSData alloc] initWithBytes:[receDataBuffer bytes] length:[receDataBuffer length]] autorelease] ;
	//delete old buffer
	[receDataBuffer setLength:0] ;
	return myData ;
};

-(bool)Socket_SendData:(NSData*) sendBuffer 
{
	if (GET_BIT(PortStatus_Whether_Connect_Success))
	{
		if (sendBuffer==nil)
			return true ;
		
		int wordsWritten;
		char *cData= malloc([sendBuffer length] + 1) ;
		memset(cData,'\0',[sendBuffer length]+1) ;
		[sendBuffer getBytes:cData] ;
		wordsWritten = send(listenSocket,cData,[sendBuffer length],0) ;
		free(cData);	
		//NSLog(@"\n socket send data %d\n",wordsWritten);
		//post a nofification to notification-center
		NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObject:sendBuffer forKey:@"SENDDATA"] ;
		if (portID!=nil)
			[d setValue:portID forKey:DeviceID] ;
		
		NSNotification *myNotification = [[NSNotification notificationWithName:MACOS_COMM_SEND_CHAR object:self userInfo:d] retain] ;
		[[NSNotificationCenter defaultCenter] postNotification:myNotification] ;
		[myNotification release] ;
		///end post notification 
		
		return true ;
	}
	return false ;
};

- (void)Socket_fileHandleThread
{		
	int wordsRead = 0;
	char tempRecBuffer[256] ;
	
	while (GET_BIT(PortStatus_Whether_StartThreadTurn))
	{
		NSAutoreleasePool *pool= [[NSAutoreleasePool alloc] init] ;
		memset(tempRecBuffer, 0, 256);
		wordsRead = recv(listenSocket,tempRecBuffer,255,0) ; //received socket data
		//NSLog(@"\n socket comm received rtn=%d \n",wordsRead);
		if (wordsRead>0) //read available data
		{
			[receDataBuffer appendBytes:tempRecBuffer length:wordsRead] ;
			
			//post a nofification to notification-center
			NSNotification *myNotification=nil ;
			if (portID==nil)
				myNotification = [[NSNotification notificationWithName:MACOS_COMM_RECV_CHAR object:self] retain] ;
			else
			{
				//NSDictionary *nsdTmp = [[NSDictionary dictionaryWithObject:portID forKey:DeviceID] retain];
				NSDictionary *nsdTmp = [[NSDictionary alloc] initWithObjectsAndKeys:portID,DeviceID,nil] ;
				myNotification = [[NSNotification notificationWithName:MACOS_COMM_RECV_CHAR object:self userInfo:nsdTmp] retain] ;
				[nsdTmp release];
			}
	
			[[NSNotificationCenter defaultCenter] postNotification:myNotification] ;
			[myNotification release] ;
			///end post notification 
		}else if(wordsRead<0)
		{
#if 1
			//post a nofification to notification-center
			NSNotification *myNotification=nil ;
			if (portID==nil)
				myNotification = [[NSNotification notificationWithName:MACOS_COMM_CONNECT_ABOUT object:self] retain] ;
			else
			{
				NSDictionary *nsdTmp = [[NSDictionary dictionaryWithObject:portID forKey:DeviceID] retain];
				myNotification = [[NSNotification notificationWithName:MACOS_COMM_CONNECT_ABOUT object:self userInfo:nsdTmp] retain] ;
				[nsdTmp release];
			}
			
			[[NSNotificationCenter defaultCenter] postNotification:myNotification] ;
			[myNotification release] ;
			///end post notification 
			
			SET_BIT_0(PortStatus_Whether_StartThreadTurn|PortStatus_Whether_Connect_Success) ;
			[pool release] ;
			pool=nil ;
#endif
			break ;
		}else
		{
			usleep(100000) ; //delay 100 ms
		}
		[pool release] ;
		pool = nil ;
	}
	return ;
}

//here is USB CLI function 
-(bool)USBCLI_Open 
{
    commType =TYPE_USBCLI ;
    return true ;
}

-(bool)USBCLI_IsOpen
{
    return true ;
}

-(bool)USBCLI_Close
{
    return true ;
}

-(NSData*)USBCLI_ReceiveResult 
{
	NSData *myData = [[[NSData alloc] initWithBytes:[receDataBuffer bytes] length:[receDataBuffer length]] autorelease] ;
	//delete old buffer
	[receDataBuffer setLength:0] ;
	return myData ;
}

-(bool)USBCLI_SendCmd:(NSData*)execCmd ;//execute the cli command .
{
    if (execCmd==nil || [execCmd length]==0)
        return false ;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init] ;
    
    NSString *outPutFile = [NSString stringWithFormat:@"/tmp/test%@%ld.txt",
                            [[NSData data] descriptionWithCalendarFormat:@"YYYYMMDDHHMMSS"],
                            random()];
    

    NSString *execCLIFile = [NSString stringWithFormat:@"%@ > %@",
                   [NSString stringWithCString:[execCmd bytes] encoding:NSASCIIStringEncoding],
                   outPutFile] ;
    
    
    //NSLog(@"\n %@",execCLIFile) ;
    @try 
    {
        system([execCLIFile UTF8String]) ;
    }@catch (NSException *exception) {
        [pool release] ;
        return false ;
    }
    @finally {
        ///
        //NSLog(@"\n---------this is finally ..........") ;
    }
    
    [self USBCLI_GetResultData:outPutFile] ;
    [pool release] ;
    return true ;
}

-(bool)USBCLI_GetResultData:(NSString*)strFileName 
{
    if (strFileName==nil)
        return false ;
    
    NSData*strData = [NSData dataWithContentsOfFile:strFileName] ;
    if (strData==nil)
        return false ;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init] ;
    [receDataBuffer appendData:strData] ;
    
    //post a nofification to notification-center
    NSNotification *myNotification=nil ;
    if (portID==nil)
        myNotification = [[NSNotification notificationWithName:MACOS_COMM_RECV_CHAR object:self] retain] ;
    else
    {
        NSDictionary *nsdTmp = [[NSDictionary alloc] initWithObjectsAndKeys:portID,DeviceID,nil] ;
        myNotification = [[NSNotification notificationWithName:MACOS_COMM_RECV_CHAR object:self userInfo:nsdTmp] retain] ;
        [nsdTmp release];
    }
	
    [[NSNotificationCenter defaultCenter] postNotification:myNotification] ;
    [myNotification release] ;
    ///end post notification 
    
    [pool release] ;
    return true ;
}
@end
